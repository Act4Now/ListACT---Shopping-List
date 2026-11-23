import { useCallback, useEffect, useMemo, useState } from "react";
import { createClient, type Session, type SupabaseClient } from "@supabase/supabase-js";
import { Apple, Check, CircleUserRound, House, ListChecks, LogOut, Pencil, Plus, ShoppingBag, Wallet, X, Trash2, Mic } from "lucide-react";

type Unit = "buc" | "kg" | "g" | "l" | "ml";
type Tab = "Acasă" | "Liste" | "Magazine" | "Buget" | "Profil";
type Household = { id: string; name: string; city: string | null };
type ShoppingList = { id: string; household_id: string; name: string; archived_at: string | null };
type Item = { id: string; list_id: string; name: string; quantity: number; unit: Unit; unit_price: number | null; is_purchased: boolean; store_id: string | null };
type Store = { id: string; name: string; household_id: string | null; is_system: boolean; is_active: boolean };\ntype SpeechResultLike = { 0: { transcript: string }; length: number };\ntype SpeechEventLike = { results: ArrayLike<SpeechResultLike> };\ntype SpeechRecognitionLike = { lang: string; interimResults: boolean; onresult: ((event: SpeechEventLike) => void) | null; onerror: (() => void) | null; onend: (() => void) | null; start: () => void; stop: () => void };\ntype SpeechRecognitionCtor = new () => SpeechRecognitionLike;
const units: Unit[] = ["buc", "kg", "g", "l", "ml"];
const money = (n: number) => new Intl.NumberFormat("ro-RO", { style: "currency", currency: "RON" }).format(n);
const supabaseUrl = import.meta.env.VITE_SUPABASE_URL as string | undefined;
const supabaseKey = import.meta.env.VITE_SUPABASE_PUBLISHABLE_KEY as string | undefined;
const supabase: SupabaseClient | null = supabaseUrl && supabaseKey ? createClient(supabaseUrl, supabaseKey) : null;

export default function App() {
  const [session, setSession] = useState<Session | null>(null);
  const [authReady, setAuthReady] = useState(false);
  const [tab, setTab] = useState<Tab>("Acasă");
  const [households, setHouseholds] = useState<Household[]>([]);
  const [householdId, setHouseholdId] = useState("");
  const [lists, setLists] = useState<ShoppingList[]>([]);
  const [listId, setListId] = useState("");
  const [items, setItems] = useState<Item[]>([]);
  const [stores, setStores] = useState<Store[]>([]);
  const [profile, setProfile] = useState({ display_name: "", city: "", font_size: 16 });
  const [busy, setBusy] = useState(false);
  const [message, setMessage] = useState("");
  const [email, setEmail] = useState("");
  const [password, setPassword] = useState("");
  const [authMode, setAuthMode] = useState<"login" | "signup">("login");
  const [householdName, setHouseholdName] = useState("");
  const [householdCity, setHouseholdCity] = useState("");
  const [listName, setListName] = useState("");
  const [newName, setNewName] = useState("");
  const [newQty, setNewQty] = useState("1");
  const [newUnit, setNewUnit] = useState<Unit>("buc");
  const [showAdd, setShowAdd] = useState(false);
  const [editing, setEditing] = useState<string | null>(null);
  const [draft, setDraft] = useState({ quantity: "1", unit: "buc" as Unit, price: "" });
  const [storeName, setStoreName] = useState("");\n  const [addMode, setAddMode] = useState<"bulk" | "voice" | null>(null);\n  const [bulkText, setBulkText] = useState("");\n  const [listening, setListening] = useState(false);\n  const [recognition, setRecognition] = useState<SpeechRecognitionLike | null>(null);

  const activeHousehold = households.find(h => h.id === householdId) ?? null;
  const activeList = lists.find(l => l.id === listId) ?? null;
  const total = useMemo(() => items.filter(i => !i.is_purchased && i.unit_price !== null).reduce((sum, i) => sum + Number(i.quantity) * Number(i.unit_price), 0), [items]);
  const unpriced = items.filter(i => !i.is_purchased && i.unit_price === null).length;
  const remaining = items.filter(i => !i.is_purchased).length;

  const loadHouseholds = useCallback(async () => {
    if (!supabase || !session) return;
    const { data, error } = await supabase.from("households").select("id,name,city").order("created_at");
    if (error) { setMessage(error.message); return; }
    const rows = (data ?? []) as Household[];
    setHouseholds(rows);
    setHouseholdId(current => rows.some(h => h.id === current) ? current : rows[0]?.id ?? "");
  }, [session]);

  const loadProfile = useCallback(async () => {
    if (!supabase || !session) return;
    const { data, error } = await supabase.from("profiles").select("display_name,city,font_size").eq("id", session.user.id).maybeSingle();
    if (error) { setMessage(error.message); return; }
    if (data) setProfile({ display_name: data.display_name ?? "", city: data.city ?? "", font_size: data.font_size ?? 16 });
  }, [session]);

  const loadLists = useCallback(async () => {
    if (!supabase || !householdId) { setLists([]); setListId(""); return; }
    const { data, error } = await supabase.from("shopping_lists").select("id,household_id,name,archived_at").eq("household_id", householdId).is("archived_at", null).order("created_at");
    if (error) { setMessage(error.message); return; }
    const rows = (data ?? []) as ShoppingList[];
    setLists(rows);
    setListId(current => rows.some(l => l.id === current) ? current : rows[0]?.id ?? "");
  }, [householdId]);

  const loadItems = useCallback(async () => {
    if (!supabase || !listId) { setItems([]); return; }
    const { data, error } = await supabase.from("shopping_items").select("id,list_id,name,quantity,unit,unit_price,is_purchased,store_id").eq("list_id", listId).order("created_at");
    if (error) { setMessage(error.message); return; }
    setItems((data ?? []) as Item[]);
  }, [listId]);

  const loadStores = useCallback(async () => {
    if (!supabase || !householdId) { setStores([]); return; }
    const { data, error } = await supabase.from("stores").select("id,name,household_id,is_system,is_active").eq("is_active", true).or(`is_system.eq.true,household_id.eq.${householdId}`).order("name");
    if (error) { setMessage(error.message); return; }
    setStores((data ?? []) as Store[]);
  }, [householdId]);

  useEffect(() => {
    if (!supabase) { setAuthReady(true); return; }
    supabase.auth.getSession().then(({ data }) => { setSession(data.session); setAuthReady(true); });
    const { data: listener } = supabase.auth.onAuthStateChange((_event, next) => setSession(next));
    return () => listener.subscription.unsubscribe();
  }, []);
  useEffect(() => { if (session) { void loadHouseholds(); void loadProfile(); } else { setHouseholds([]); setLists([]); setItems([]); setStores([]); } }, [session, loadHouseholds, loadProfile]);
  useEffect(() => { void loadLists(); void loadStores(); }, [householdId, loadLists, loadStores]);
  useEffect(() => { void loadItems(); }, [listId, loadItems]);
  useEffect(() => {
    if (!supabase || !listId) return;
    const channel = supabase.channel(`list-${listId}`).on("postgres_changes", { event: "*", schema: "public", table: "shopping_items", filter: `list_id=eq.${listId}` }, () => { void loadItems(); }).subscribe();
    return () => { void supabase?.removeChannel(channel); };
  }, [listId, loadItems]);

  async function signIn(provider: "google" | "apple") {
    if (!supabase) return setMessage("Lipsește configurarea VITE_SUPABASE_URL sau VITE_SUPABASE_PUBLISHABLE_KEY.");
    const { error } = await supabase.auth.signInWithOAuth({ provider, options: { redirectTo: window.location.origin } });
    if (error) setMessage(error.message);
  }
  async function emailAuth() {
    if (!supabase) return setMessage("Conexiunea Supabase nu este configurată.");
    setBusy(true); setMessage("");
    const result = authMode === "signup"
      ? await supabase.auth.signUp({ email, password })
      : await supabase.auth.signInWithPassword({ email, password });
    setBusy(false);
    if (result.error) setMessage(result.error.message);
    else if (authMode === "signup" && !result.data.session) setMessage("Cont creat. Verifică e-mailul pentru confirmarea adresei.");
  }
  async function signOut() { if (supabase) await supabase.auth.signOut(); }
  async function createHousehold() {
    if (!supabase || !householdName.trim()) return;
    setBusy(true);
    const { error } = await supabase.rpc("create_household", { p_name: householdName.trim(), p_city: householdCity.trim() || null });
    setBusy(false);
    if (error) { setMessage(error.message); return; }
    setHouseholdName(""); setHouseholdCity(""); setMessage("Gospodăria a fost creată."); await loadHouseholds();
  }
  async function createList() {
    if (!supabase || !householdId || !listName.trim()) return;
    setBusy(true);
    const { data, error } = await supabase.from("shopping_lists").insert({ household_id: householdId, name: listName.trim() }).select("id").single();
    setBusy(false);
    if (error) { setMessage(error.message); return; }
    setListName(""); await loadLists(); if (data) setListId(data.id);
  }
  async function addItem() {
    if (!supabase || !listId || !newName.trim()) return;
    const qty = Number(newQty);
    if (!Number.isFinite(qty) || qty <= 0) return setMessage("Cantitatea trebuie să fie mai mare decât zero.");
    setBusy(true);
    const { error } = await supabase.rpc("add_shopping_item", { p_list_id: listId, p_name: newName.trim(), p_quantity: qty, p_unit: newUnit });
    setBusy(false);
    if (error) { setMessage(error.message); return; }
    setNewName(""); setNewQty("1"); setNewUnit("buc"); setShowAdd(false); await loadItems();
  }
  async function togglePurchased(item: Item) {
    if (!supabase) return;
    const next = !item.is_purchased;
    const { error } = await supabase.from("shopping_items").update({ is_purchased: next, purchased_at: next ? new Date().toISOString() : null, updated_at: new Date().toISOString() }).eq("id", item.id);
    if (error) setMessage(error.message); else await loadItems();
  }
  function startEdit(item: Item) {
    setEditing(item.id);
    setDraft({ quantity: String(item.quantity), unit: item.unit, price: item.unit_price === null ? "" : String(item.unit_price) });
  }
  async function saveEdit(id: string) {
    if (!supabase) return;
    const quantity = Number(draft.quantity);
    const price = draft.price.trim() === "" ? null : Number(draft.price);
    if (!Number.isFinite(quantity) || quantity <= 0 || (price !== null && (!Number.isFinite(price) || price < 0))) return setMessage("Verifică valoarea cantității și a prețului.");
    const { error } = await supabase.from("shopping_items").update({ quantity, unit: draft.unit, unit_price: price, updated_at: new Date().toISOString() }).eq("id", id);
    if (error) setMessage(error.message); else { setEditing(null); await loadItems(); }
  }
  async function deleteItem(id: string) {
    if (!supabase || !window.confirm("Ștergi produsul din listă?")) return;
    const { error } = await supabase.from("shopping_items").delete().eq("id", id);
    if (error) setMessage(error.message); else await loadItems();
  }
  async function saveProfile() {
    if (!supabase || !session) return;
    const { error } = await supabase.from("profiles").upsert({ id: session.user.id, display_name: profile.display_name.trim() || null, city: profile.city.trim() || null, font_size: profile.font_size, updated_at: new Date().toISOString() });
    setMessage(error ? error.message : "Profil salvat.");
  }
  async function addStore() {
    if (!supabase || !householdId || !storeName.trim() || !session) return;
    const { error } = await supabase.from("stores").insert({ household_id: householdId, name: storeName.trim(), is_system: false, created_by: session.user.id });
    if (error) setMessage(error.message); else { setStoreName(""); await loadStores(); }
  }
  const bulkNames = bulkText.split(/[\\n,;]+/).map(n => n.trim()).filter(Boolean);\n  const normalizedExisting = new Set(items.map(i => i.name.trim().toLocaleLowerCase("ro")));\n  const bulkDuplicates = bulkNames.filter((n, i) => normalizedExisting.has(n.toLocaleLowerCase("ro")) || bulkNames.slice(0, i).some(p => p.toLocaleLowerCase("ro") === n.toLocaleLowerCase("ro")));\n  function startVoice() {\n    const browser = window as Window & { SpeechRecognition?: SpeechRecognitionCtor; webkitSpeechRecognition?: SpeechRecognitionCtor };\n    const Ctor = browser.SpeechRecognition ?? browser.webkitSpeechRecognition;\n    if (!Ctor) { setMessage("Dictarea vocală nu este disponibilă în acest browser. Poți introduce produsele manual în aceeași zonă."); return; }\n    const instance = new Ctor(); instance.lang = "ro-RO"; instance.interimResults = false;\n    instance.onresult = event => { const transcript = Array.from(event.results).map(r => r[0].transcript).join(" "); setBulkText(current => current ? current + "\\n" + transcript : transcript); };\n    instance.onerror = () => { setListening(false); setMessage("Nu am putut recunoaște vocea. Verifică permisiunea microfonului și încearcă din nou."); };\n    instance.onend = () => setListening(false);\n    setRecognition(instance); setListening(true);\n    try { instance.start(); } catch { setListening(false); setMessage("Dictarea nu a putut porni. Încearcă din nou."); }\n  }\n  async function submitBulk() {\n    if (!supabase || !listId || bulkNames.length === 0) return;\n    setBusy(true);\n    const payload = bulkNames.map(name => ({ name, quantity: 1, unit: "buc" }));\n    const { error } = await supabase.rpc("add_shopping_items_bulk", { p_list_id: listId, p_items: payload });\n    setBusy(false);\n    if (error) { setMessage(error.message); return; }\n    setMessage(bulkDuplicates.length ? "Produsele au fost adăugate. Duplicatele au fost reunite conform regulilor listei." : "Produsele au fost adăugate.");\n    setBulkText(""); setAddMode(null); await loadItems();\n  }\n  async function archiveList() {
    if (!supabase || !activeList || !window.confirm("Arhivezi lista? Produsele vor rămâne păstrate.")) return;
    const { error } = await supabase.from("shopping_lists").update({ archived_at: new Date().toISOString() }).eq("id", activeList.id);
    if (error) setMessage(error.message); else { setListId(""); await loadLists(); }
  }

  const nav = [
    { label: "Acasă" as Tab, icon: House }, { label: "Liste" as Tab, icon: ListChecks },
    { label: "Magazine" as Tab, icon: ShoppingBag }, { label: "Buget" as Tab, icon: Wallet }, { label: "Profil" as Tab, icon: CircleUserRound },
  ];
  if (!authReady) return <div className="center-screen"><div className="brand-mark">L</div><p>Se încarcă ListACT…</p></div>;
  if (!session) return <div className="auth-shell"><div className="auth-card"><a className="brand" href="#"><span className="brand-mark">L</span><span>List<span className="brand-accent">ACT</span></span></a><p className="eyebrow">CUMPĂRĂTURI ÎMPREUNĂ</p><h1>{authMode === "login" ? "Bine ai revenit!" : "Creează-ți contul"}</h1><p className="subtle">Liste simple, buget clar, toată familia conectată.</p><label>E-mail<input type="email" autoComplete="email" value={email} onChange={e => setEmail(e.target.value)} placeholder="adresa@exemplu.ro"/></label><label>Parolă<input type="password" autoComplete={authMode === "login" ? "current-password" : "new-password"} value={password} onChange={e => setPassword(e.target.value)} placeholder="Cel puțin 8 caractere"/></label><button className="primary-button full" disabled={busy || !email || password.length < 8} onClick={() => void emailAuth()}>{busy ? "Se procesează…" : authMode === "login" ? "Autentificare" : "Creează cont"}</button><div className="auth-divider"><span>sau</span></div><button className="oauth-button" onClick={() => void signIn("google")}>Continuă cu Google</button><button className="oauth-button" onClick={() => void signIn("apple")}><Apple size={17}/> Continuă cu Apple</button><p className="auth-switch">{authMode === "login" ? "Nu ai cont?" : "Ai deja cont?"} <button onClick={() => setAuthMode(authMode === "login" ? "signup" : "login")}>{authMode === "login" ? "Înregistrează-te" : "Autentifică-te"}</button></p>{message && <p className="notice">{message}</p>} {!supabase && <p className="notice">Configurarea publică Supabase lipsește din mediul de rulare.</p>}</div></div>;

  return <div className="app-shell" style={{ fontSize: profile.font_size }}>
    <header className="topbar"><a className="brand" href="#"><span className="brand-mark">L</span><span>List<span className="brand-accent">ACT</span></span></a><div className="top-actions">{households.length > 0 && <select aria-label="Gospodărie activă" className="household-select" value={householdId} onChange={e => setHouseholdId(e.target.value)}>{households.map(h => <option key={h.id} value={h.id}>{h.name}</option>)}</select>}<button className="avatar" onClick={() => setTab("Profil")} aria-label="Profil"><CircleUserRound size={21}/></button></div></header>
    <main className="main-content">
      <div className="welcome"><div><p className="eyebrow">{activeHousehold?.name.toLocaleUpperCase("ro") ?? "GOSPODĂRIA MEA"}</p><h1>{tab === "Liste" ? "Liste de cumpărături" : tab}</h1><p className="subtle">Tot ce ai nevoie, într-un singur loc.</p></div><span className="date-pill">{activeHousehold?.city || "Oraș nesetat"}</span></div>
      {!activeHousehold ? <section className="list-panel empty-state"><House size={30}/><h2>Începe cu gospodăria ta</h2><p>Creează o gospodărie pentru a putea colabora la liste cu familia.</p><div className="inline-create"><input placeholder="Numele gospodăriei" value={householdName} onChange={e => setHouseholdName(e.target.value)}/><input placeholder="Oraș (opțional)" value={householdCity} onChange={e => setHouseholdCity(e.target.value)}/><button className="primary-button" disabled={busy || !householdName.trim()} onClick={() => void createHousehold()}>Creează</button></div></section> : <>
      {tab === "Acasă" && <><section className="summary-grid"><article className="summary-card"><span>Liste active</span><strong>{lists.length}</strong><small>în gospodărie</small></article><article className="summary-card budget-card"><span>Buget listă selectată</span><strong>{money(total)}</strong><small>{unpriced} produse fără preț</small></article></section><section className="list-panel"><div className="list-heading"><div><h2>Lista curentă</h2><p>{remaining} produse de cumpărat</p></div><button className="primary-button" onClick={() => setTab("Liste")}>Deschide lista</button></div></section></>}
      {tab === "Liste" && <section className="list-panel"><div className="list-heading"><div><h2>Listele gospodăriei</h2><p>Alege o listă sau creează una nouă</p></div></div><div className="list-picker">{lists.map(l => <button key={l.id} className={l.id === listId ? "list-chip selected" : "list-chip"} onClick={() => setListId(l.id)}>{l.name}</button>)}</div><div className="inline-create"><input placeholder="Numele unei liste noi" value={listName} onChange={e => setListName(e.target.value)} onKeyDown={e => e.key === "Enter" && void createList()}/><button className="primary-button" disabled={busy || !listName.trim()} onClick={() => void createList()}><Plus size={16}/> Creează lista</button></div>
      {activeList && <><div className="list-heading list-heading-lower"><div><h2>{activeList.name}</h2><p>{remaining} produse de cumpărat</p></div><button className="icon-button" aria-label="Arhivează lista" onClick={() => void archiveList()}><Trash2 size={17}/></button></div><section className="summary-grid compact"><article className="summary-card"><span>Produse rămase</span><strong>{remaining}</strong></article><article className="summary-card budget-card"><span>Buget estimat</span><strong>{money(total)}</strong><small>{unpriced} fără preț</small></article></section><div className="product-list">{items.map(item => <div className={`product-row ${item.is_purchased ? "is-bought" : ""}`} key={item.id}><button className={`check-button ${item.is_purchased ? "checked" : ""}`} aria-label={item.is_purchased ? "Marchează necumpărat" : "Marchează cumpărat"} onClick={() => void togglePurchased(item)}>{item.is_purchased && <Check size={15}/>}</button><span className="product-name">{item.name}</span>{editing === item.id ? <div className="edit-fields"><input aria-label="Cantitate" type="number" min="0.01" step="0.01" value={draft.quantity} onChange={e => setDraft(d => ({...d,quantity:e.target.value}))}/><select aria-label="Unitate" value={draft.unit} onChange={e => setDraft(d => ({...d,unit:e.target.value as Unit}))}>{units.map(u => <option key={u}>{u}</option>)}</select><input aria-label="Preț unitar în lei" type="number" min="0" step="0.01" placeholder="Preț" value={draft.price} onChange={e => setDraft(d => ({...d,price:e.target.value}))}/><button className="save-button" onClick={() => void saveEdit(item.id)} aria-label="Salvează"><Check size={16}/></button><button className="cancel-button" onClick={() => setEditing(null)} aria-label="Anulează"><X size={16}/></button></div> : <><span className="quantity">{item.quantity}</span><span className="unit">{item.unit}</span><span className="price">{item.unit_price === null ? "—" : money(Number(item.unit_price) * Number(item.quantity))}</span><button className="edit-button" onClick={() => startEdit(item)} aria-label={`Editează ${item.name}`}><Pencil size={16}/></button><button className="edit-button" onClick={() => void deleteItem(item.id)} aria-label={`Șterge ${item.name}`}><X size={16}/></button></>}</div>)}</div>
      <div className="quick-actions"><button onClick={() => { setAddMode(addMode === "bulk" ? null : "bulk"); setShowAdd(false); }}><Plus size={17}/> Adăugare în masă</button><button onClick={() => { setAddMode(addMode === "voice" ? null : "voice"); setShowAdd(false); }}><Mic size={17}/> Adăugare vocală</button></div>
      {addMode && <section className="bulk-panel"><div className="list-heading"><div><h2>{addMode === "voice" ? "Adăugare vocală" : "Adăugare în masă"}</h2><p>{addMode === "voice" ? "Vorbește în română sau editează transcrierea." : "Un produs pe rând sau separate prin virgulă."}</p></div><button className="icon-button" onClick={() => { recognition?.stop(); setListening(false); setAddMode(null); }} aria-label="Închide"><X size={17}/></button></div>
      {addMode === "voice" && <button className="primary-button voice-button" onClick={() => listening ? recognition?.stop() : startVoice()}><Mic size={17}/>{listening ? "Oprește dictarea" : "Începe dictarea"}</button>}
      <textarea rows={4} placeholder={"Lapte\\nPâine\\nBanane"} value={bulkText} onChange={e => setBulkText(e.target.value)}/>
      <div className="bulk-meta"><span>{bulkNames.length} produse detectate</span>{bulkDuplicates.length > 0 && <strong>{bulkDuplicates.length} posibile duplicate — verifică înainte de adăugare</strong>}</div>
      {bulkNames.length > 0 && <ul className="bulk-preview">{bulkNames.map((name,i) => <li key={i}>{name}{bulkDuplicates.some(d => d.toLocaleLowerCase("ro") === name.toLocaleLowerCase("ro")) && <small> posibil duplicat</small>}</li>)}</ul>}
      <div className="bulk-actions"><button className="primary-button" disabled={busy || bulkNames.length === 0} onClick={() => void submitBulk()}>{busy ? "Se adaugă…" : "Confirmă și adaugă"}</button><button className="cancel-button" onClick={() => { recognition?.stop(); setListening(false); setAddMode(null); }}>Anulează</button></div></section>}
      {showAdd ? <div className="add-form"><input autoFocus placeholder="Denumire produs" value={newName} onChange={e => setNewName(e.target.value)} onKeyDown={e => e.key === "Enter" && void addItem()}/><input aria-label="Cantitate" type="number" min="0.01" step="0.01" value={newQty} onChange={e => setNewQty(e.target.value)}/><select aria-label="Unitate" value={newUnit} onChange={e => setNewUnit(e.target.value as Unit)}>{units.map(u => <option key={u}>{u}</option>)}</select><button className="primary-button" disabled={busy} onClick={() => void addItem()}>Adaugă</button><button className="cancel-button" onClick={() => setShowAdd(false)}><X size={18}/></button></div> : <button className="add-product" onClick={() => setShowAdd(true)}><Plus size={18}/> Adaugă produs</button>}
      <div className="list-footer"><span>Prețuri introduse manual; fără estimări inventate</span><strong>{money(total)}</strong></div></>}
      {!activeList && lists.length === 0 && <p className="empty-hint">Nu ai încă liste. Creează prima listă mai sus.</p>}</section>}
      {tab === "Magazine" && <section className="list-panel"><div className="list-heading"><div><h2>Magazine</h2><p>Magazine comune și proprii gospodăriei</p></div></div><div className="inline-create"><input placeholder="Numele magazinului" value={storeName} onChange={e => setStoreName(e.target.value)} onKeyDown={e => e.key === "Enter" && void addStore()}/><button className="primary-button" onClick={() => void addStore()} disabled={!storeName.trim()}><Plus size={16}/> Adaugă</button></div>{stores.length ? stores.map(s => <div className="store-row" key={s.id}><ShoppingBag size={17}/><span>{s.name}</span><small>{s.is_system ? "Magazin global" : "Gospodăria mea"}</small></div>) : <p className="empty-hint">Nu există magazine configurate încă.</p>}</section>}
      {tab === "Buget" && <section className="list-panel placeholder-card"><Wallet/><h2>Bugetul listei</h2><strong className="big-total">{money(total)}</strong><p>Totalul include doar produsele necumpărate cu preț introdus. Produse fără preț: {unpriced}.</p><p className="subtle">Nu sunt afișate prețuri online până când sursele gratuite și drepturile de reutilizare nu sunt verificate.</p></section>}
      {tab === "Profil" && <section className="list-panel profile-form"><CircleUserRound/><h2>Profil și preferințe</h2><label>Nume afișat<input value={profile.display_name} onChange={e => setProfile(p => ({...p,display_name:e.target.value}))}/></label><label>Oraș implicit pentru gospodării noi<input value={profile.city} onChange={e => setProfile(p => ({...p,city:e.target.value}))} placeholder="Ex. București"/></label><label>Dimensiunea textului<select value={profile.font_size} onChange={e => setProfile(p => ({...p,font_size:Number(e.target.value)}))}>{[16,18,20,22].map(n => <option key={n} value={n}>{n}px</option>)}</select></label><button className="primary-button" onClick={() => void saveProfile()}>Salvează profilul</button><button className="oauth-button logout" onClick={() => void signOut()}><LogOut size={17}/> Deconectare</button></section>}
      </>}
      {message && <p className="notice">{message}<button onClick={() => setMessage("")}><X size={14}/></button></p>}
      </main>
    <nav className="bottom-nav">{nav.map(({label,icon:Icon}) => <button key={label} className={tab === label ? "active" : ""} onClick={() => setTab(label)}><Icon size={20}/><span>{label}</span></button>)}</nav>
  </div>;
}
