import { useMemo, useState } from "react";
import { createClient, type SupabaseClient } from "@supabase/supabase-js";
import { Apple, Check, CircleUserRound, House, ListChecks, Mic, Pencil, Plus, Settings, ShoppingBag, Wallet, X } from "lucide-react";

type Unit = "buc" | "kg" | "g" | "l" | "ml";
type Item = { id: string; name: string; quantity: number; unit: Unit; price: number | null; bought: boolean };
type Tab = "Acasă" | "Liste" | "Magazine" | "Buget" | "Profil";
const initialItems: Item[] = [
  { id: "1", name: "Lapte", quantity: 2, unit: "buc", price: 12.5, bought: false },
  { id: "2", name: "Pâine", quantity: 1, unit: "buc", price: 5, bought: false },
  { id: "3", name: "Banane", quantity: 1.5, unit: "kg", price: 9.9, bought: false },
  { id: "4", name: "Iaurt", quantity: 4, unit: "buc", price: 12, bought: true },
];
const units: Unit[] = ["buc", "kg", "g", "l", "ml"];
const money = (n: number) => new Intl.NumberFormat("ro-RO", { style: "currency", currency: "RON" }).format(n);
const supabaseUrl = import.meta.env.VITE_SUPABASE_URL as string | undefined;
const supabaseKey = import.meta.env.VITE_SUPABASE_PUBLISHABLE_KEY as string | undefined;
const supabase: SupabaseClient | null = supabaseUrl && supabaseKey ? createClient(supabaseUrl, supabaseKey) : null;

export default function App() {
  const [tab, setTab] = useState<Tab>("Liste");
  const [items, setItems] = useState(initialItems);
  const [newName, setNewName] = useState("");
  const [newQty, setNewQty] = useState("1");
  const [newUnit, setNewUnit] = useState<Unit>("buc");
  const [editing, setEditing] = useState<string | null>(null);
  const [draft, setDraft] = useState({ quantity: "1", unit: "buc" as Unit, price: "" });
  const [authMessage, setAuthMessage] = useState("");
  const [showAdd, setShowAdd] = useState(false);
  const total = useMemo(() => items.filter(i => !i.bought && i.price !== null).reduce((sum, i) => sum + i.quantity * (i.price ?? 0), 0), [items]);
  const unpriced = items.filter(i => !i.bought && i.price === null).length;

  async function signIn(provider: "google" | "apple") {
    if (!supabase) { setAuthMessage("Conectarea la Supabase va fi activată după configurarea cheii publice."); return; }
    const { error } = await supabase.auth.signInWithOAuth({ provider, options: { redirectTo: window.location.origin } });
    if (error) setAuthMessage(error.message);
  }
  function addItem() {
    const name = newName.trim();
    const qty = Number(newQty);
    if (!name || !Number.isFinite(qty) || qty <= 0) return;
    const exact = items.find(i => i.name.toLocaleLowerCase("ro") === name.toLocaleLowerCase("ro") && i.unit === newUnit);
    if (exact && !exact.bought) {
      setItems(old => old.map(i => i.id === exact.id ? { ...i, quantity: i.quantity + qty } : i));
    } else if (exact && exact.bought) {
      setItems(old => old.map(i => i.id === exact.id ? { ...i, bought: false, quantity: 1, unit: "buc" } : i));
    } else {
      setItems(old => [...old, { id: crypto.randomUUID(), name, quantity: qty, unit: newUnit, price: null, bought: false }]);
    }
    setNewName(""); setNewQty("1"); setNewUnit("buc"); setShowAdd(false);
  }
  function startEdit(item: Item) {
    setEditing(item.id);
    setDraft({ quantity: String(item.quantity), unit: item.unit, price: item.price === null ? "" : String(item.price) });
  }
  function saveEdit(id: string) {
    const quantity = Number(draft.quantity);
    const price = draft.price.trim() === "" ? null : Number(draft.price);
    if (!Number.isFinite(quantity) || quantity <= 0 || (price !== null && (!Number.isFinite(price) || price < 0))) return;
    setItems(old => old.map(i => i.id === id ? { ...i, quantity, unit: draft.unit, price } : i));
    setEditing(null);
  }
  const nav = [
    { label: "Acasă" as Tab, icon: House }, { label: "Liste" as Tab, icon: ListChecks },
    { label: "Magazine" as Tab, icon: ShoppingBag }, { label: "Buget" as Tab, icon: Wallet }, { label: "Profil" as Tab, icon: CircleUserRound },
  ];
  return <div className="app-shell">
    <header className="topbar"><a className="brand" href="#"><span className="brand-mark">L</span><span>List<span className="brand-accent">ACT</span></span></a><button className="avatar" onClick={() => setTab("Profil")} aria-label="Profil"><CircleUserRound size={21}/></button></header>
    <main className="main-content">
      <div className="welcome"><div><p className="eyebrow">GOSPODĂRIA MEA</p><h1>{tab === "Liste" ? "Lista de cumpărături" : tab}</h1><p className="subtle">Tot ce ai nevoie, într-un singur loc.</p></div><span className="date-pill">Astăzi</span></div>
      {tab === "Liste" && <>
        <section className="summary-grid"><article className="summary-card"><span>Produse rămase</span><strong>{items.filter(i => !i.bought).length}</strong><small>în lista activă</small></article><article className="summary-card budget-card"><span>Buget estimat</span><strong>{money(total)}</strong><small>{unpriced ? unpriced + " produse fără preț" : "pentru produsele cu preț"}</small></article></section>
        <section className="list-panel"><div className="list-heading"><div><h2>Cumpărături săptămânale</h2><p>{items.filter(i => !i.bought).length} produse de cumpărat</p></div><button className="icon-button" aria-label="Setări listă"><Settings size={18}/></button></div>
          <div className="product-list">{items.map(item => <div className={`product-row ${item.bought ? "is-bought" : ""}`} key={item.id}>
            <button className={`check-button ${item.bought ? "checked" : ""}`} aria-label={item.bought ? "Marchează necumpărat" : "Marchează cumpărat"} onClick={() => setItems(old => old.map(i => i.id === item.id ? { ...i, bought: !i.bought } : i))}>{item.bought && <Check size={15}/>}</button>
            <span className="product-name">{item.name}</span>
            {editing === item.id ? <div className="edit-fields">
              <input aria-label="Cantitate" type="number" min="0.01" step="0.01" value={draft.quantity} onChange={e => setDraft(d => ({ ...d, quantity: e.target.value }))}/>
              <select aria-label="Unitate" value={draft.unit} onChange={e => setDraft(d => ({ ...d, unit: e.target.value as Unit }))}>{units.map(u => <option key={u}>{u}</option>)}</select>
              <input aria-label="Preț în lei" type="number" min="0" step="0.01" placeholder="Preț" value={draft.price} onChange={e => setDraft(d => ({ ...d, price: e.target.value }))}/>
              <button className="save-button" onClick={() => saveEdit(item.id)} aria-label="Salvează"><Check size={16}/></button>
              <button className="cancel-button" onClick={() => setEditing(null)} aria-label="Anulează"><X size={16}/></button>
            </div> : <>
              <span className="quantity">{item.quantity}</span><span className="unit">{item.unit}</span>
              <span className="price">{item.price === null ? "—" : money(item.price * item.quantity)}</span>
              <button className="edit-button" onClick={() => startEdit(item)} aria-label={`Editează ${item.name}`}><Pencil size={16}/></button>
            </>}
          </div>)}</div>
          {showAdd ? <div className="add-form"><input autoFocus placeholder="Denumire produs" value={newName} onChange={e => setNewName(e.target.value)} onKeyDown={e => e.key === "Enter" && addItem()}/><input aria-label="Cantitate nouă" type="number" min="0.01" step="0.01" value={newQty} onChange={e => setNewQty(e.target.value)}/><select aria-label="Unitate nouă" value={newUnit} onChange={e => setNewUnit(e.target.value as Unit)}>{units.map(u => <option key={u}>{u}</option>)}</select><button className="primary-button" onClick={addItem}>Adaugă</button><button className="cancel-button" onClick={() => setShowAdd(false)}><X size={18}/></button></div> : <button className="add-product" onClick={() => setShowAdd(true)}><Plus size={18}/> Adaugă produs</button>}
          <div className="list-footer"><span>Bugetul se actualizează automat</span><strong>{money(total)}</strong></div>
        </section>
      </>}
      {tab === "Acasă" && <section className="welcome-card"><div className="welcome-icon"><ListChecks/></div><h2>Bine ai venit în ListACT</h2><p>Organizează cumpărăturile împreună cu familia.</p><button className="primary-button" onClick={() => setTab("Liste")}>Deschide lista</button></section>}
      {tab === "Magazine" && <section className="placeholder-card"><ShoppingBag/><h2>Magazine</h2><p>Magazinele globale și cele ale gospodăriei vor fi disponibile aici.</p></section>}
      {tab === "Buget" && <section className="placeholder-card"><Wallet/><h2>Bugetul listei</h2><strong className="big-total">{money(total)}</strong><p>Estimare calculată din prețurile introduse. Produse fără preț: {unpriced}.</p></section>}
      {tab === "Profil" && <section className="placeholder-card"><CircleUserRound/><h2>Contul tău</h2><p>Autentificare și setări de profil</p><div className="auth-buttons"><button onClick={() => signIn("google")}>Continuă cu Google</button><button onClick={() => signIn("apple")}><Apple size={17}/> Continuă cu Apple</button></div>{authMessage && <p className="notice">{authMessage}</p>}</section>}
      {tab === "Liste" && <div className="quick-actions"><button onClick={() => setAuthMessage("Adăugarea vocală va fi activată într-o etapă următoare.")}><Mic size={17}/> Adăugare vocală</button><button onClick={() => setAuthMessage("Adăugarea în masă va fi activată într-o etapă următoare.")}><Plus size={17}/> Adăugare în masă</button></div>}
      {authMessage && tab !== "Profil" && <p className="notice">{authMessage}<button onClick={() => setAuthMessage("")}><X size={14}/></button></p>}
    </main>
    <nav className="bottom-nav">{nav.map(({label,icon:Icon}) => <button key={label} className={tab === label ? "active" : ""} onClick={() => setTab(label)}><Icon size={20}/><span>{label}</span></button>)}</nav>
  </div>;
}