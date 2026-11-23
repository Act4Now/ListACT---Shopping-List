# Starea verificată a dezvoltării ListACT

Ultima verificare: 23 noiembrie 2026.

## Ramură și medii
- Toate modificările de dezvoltare se fac pe `develop`.
- `main` nu a fost modificată și aplicația nu a fost publicată.
- Supabase activ: proiectul ListACT din regiunea eu-central-2.

## Funcții implementate în interfață
- Autentificare e-mail/parolă și înregistrare.
- Inițiere OAuth Google și Apple (necesită configurarea furnizorilor în Supabase și în consolele Google/Apple).
- Recuperare parolă prin e-mail și actualizare parolă după revenirea din link.
- Gospodării multiple, redenumire și editarea orașului.
- Conectare prin link cu token aleatoriu de 256 biți; în baza de date se păstrează hash-ul tokenului. Efectul de acceptare este protejat împotriva procesării duble inclusiv în React Strict Mode.
- Revocare și regenerare link; eliminarea membrilor și transferul rolului de proprietar.
- Liste multiple, arhivare, produse individuale și în masă, dictare vocală dependentă de browser.
- Sincronizare Realtime pentru produsele listei.
- Magazine globale și magazine personalizate, cu redenumire/dezactivare.
- Cantități, unități și preț unitar comun salvat pe produs; orice membru al gospodăriei poate modifica prețul, iar Realtime propagă schimbarea către toți membrii conectați la lista respectivă. Bugetul este calculat din același preț comun.

## Securitate verificată
- RLS este activ pe toate cele 16 tabele publice.
- Tabela linkurilor de gospodărie refuză accesul direct prin RLS; operațiile sunt făcute prin RPC.
- Funcțiile privilegiate sunt implementate în schema privată; funcțiile RPC publice sunt SECURITY INVOKER.
- Funcțiile administrative și linkurile de gospodărie nu sunt executabile de rolul anon.
- RPC-ul vechi de invitații prin e-mail nu mai poate fi executat.
- Advisor-ul Supabase pentru securitate și health nu a raportat lint-uri la ultima verificare.
- Este impus un singur proprietar per gospodărie prin index unic parțial; transferul blochează rândul gospodăriei și schimbă rolurile tranzacțional.

## Istoricul prețurilor personale (migrare istorică)
- Migrarea `20261123185156_personal_price_overrides_per_user` a fost aplicată în Supabase și este păstrată în repository pentru reproducerea fidelă a istoricului.
- Această tabelă este o componentă istorică nefolosită de interfața actuală. Prețul utilizat de ListACT rămâne `shopping_items.unit_price`, comun gospodăriei.
- Tabela `list_item_price_overrides` este goală la ultima verificare și rămâne deocamdată în schema bazei de date; nu este citită sau modificată de aplicația curentă.

## Sincronizarea prețurilor între membrii gospodăriei
- Prețul comun este `shopping_items.unit_price`; interfața nu mai citește și nu mai scrie suprascrieri individuale din `list_item_price_overrides`.
- Modificarea prețului actualizează rândul produsului, iar abonarea Realtime la `shopping_items` reîncarcă lista pentru toți membrii conectați.
- La verificarea din 23 noiembrie 2026, tabela `list_item_price_overrides` nu conținea rânduri; nu a fost necesară reconcilierea unor prețuri personale istorice.
- Tabela veche rămâne în baza de date pentru moment, dar nu mai este folosită de interfață.

## Sincronizarea migrațiilor
- Toate cele 20 de migrări înregistrate în Supabase au acum fișiere SQL corespunzătoare în `supabase/migrations` pe ramura `develop`.
- Primele 10 migrări istorice și migrarea 20 au fost recuperate din coloana `statements` a tabelului intern `supabase_migrations.schema_migrations`; conținutul SQL a fost păstrat fără rescriere.
- Fișierele 11–19 existau deja în repository.
- Recuperarea fișierelor nu a rulat din nou migrările pe proiectul Supabase activ și nu a modificat schema sau datele acestuia.
- Istoricul este sincronizat la nivel de fișiere și versiuni înregistrate; o instalare curată pe un proiect Supabase separat nu a fost executată.

## Audit final de implementare — 23 noiembrie 2026
- Prețurile individuale au fost eliminate din fluxul aplicației; `shopping_items.unit_price` este prețul comun al produsului și este accesibil membrilor gospodăriei conform RLS.
- Abonarea Realtime la `shopping_items` este activă, iar tabela este inclusă în publicația `supabase_realtime`.
- README-ul a fost corectat pentru a descrie prețurile comune și linkurile de conectare, nu prețurile personale sau invitațiile vechi prin e-mail.
- Interfața nu implementează ștergerea definitivă a listelor; oferă arhivarea lor.
- Integrarea automată a prețurilor online, notificările push/e-mail și trimiterea automată a invitațiilor nu sunt implementate.
- Schema de prețuri online este doar fundație de date; nu există colectare/estimare automată activă.

## Configurare și publicare — în pregătire
- Proiectul Supabase activ și cheia publishable curentă au fost verificate; `.env.example` corespunde proiectului ListACT.
- Nu există încă domeniu, furnizor de hosting sau setări de deploy alese în mod explicit; acestea nu au fost configurate automat.
- URL-ul Site URL și Redirect URLs din Supabase Auth trebuie completate cu domeniul final după alegerea hostingului.
- Google/Apple OAuth rămâne opțional și necesită credențiale în consolele furnizorilor și în Supabase.
- E-mailurile de confirmare și recuperare necesită configurarea adecvată a serviciului de e-mail pentru producție.
- Build-ul TypeScript/Vite nu este încă confirmat cu un rezultat CI reușit.
- Testele de acceptanță cu două conturi sunt planificate de utilizator pentru producție.
- Dictarea vocală depinde de suportul browserului și permisiunea microfonului.
- Prețurile online nu sunt integrate; nu se folosesc API-uri plătite sau surse fără drepturi de reutilizare confirmate.

Acest document separă funcțiile existente de verificările care încă trebuie executate. Nu reprezintă o certificare de lansare.
