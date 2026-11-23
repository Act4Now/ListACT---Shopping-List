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
- Conectare prin link cu token aleatoriu de 256 biți; în baza de date se păstrează hash-ul tokenului.
- Revocare și regenerare link; eliminarea membrilor și transferul rolului de proprietar.
- Liste multiple, arhivare, produse individuale și în masă, dictare vocală dependentă de browser.
- Sincronizare Realtime pentru produsele listei.
- Magazine globale și magazine personalizate, cu redenumire/dezactivare.
- Cantități, unități, prețuri și suprascrieri personale; buget calculat din prețurile disponibile.

## Securitate verificată
- RLS este activ pe toate cele 16 tabele publice.
- Tabela linkurilor de gospodărie refuză accesul direct prin RLS; operațiile sunt făcute prin RPC.
- Funcțiile privilegiate sunt implementate în schema privată; funcțiile RPC publice sunt SECURITY INVOKER.
- Funcțiile administrative și linkurile de gospodărie nu sunt executabile de rolul anon.
- RPC-ul vechi de invitații prin e-mail nu mai poate fi executat.
- Advisor-ul Supabase pentru securitate și health nu a raportat lint-uri la ultima verificare.
- Este impus un singur proprietar per gospodărie prin index unic parțial; transferul blochează rândul gospodăriei și schimbă rolurile tranzacțional.

## Sincronizarea migrațiilor — lucru rămas
Migrațiile recente pentru linkuri și administrarea gospodăriilor sunt salvate în `supabase/migrations` și au fost aplicate în Supabase.

**Atenție:** primele 10 migrații istorice (schema inițială, RPC-uri, Realtime, magazine și schema de prețuri) există în istoricul proiectului Supabase, dar fișierele lor SQL nu se găsesc în repository. Nu recrea un proiect Supabase nou folosind doar folderul actual de migrații: istoricul de bază trebuie recuperat/reconstituit și verificat înainte de a putea declara instalarea reproductibilă de la zero.

## Testare și lansare — încă neconfirmate
- Build-ul TypeScript/Vite nu a fost confirmat cu un rezultat CI vizibil pentru ultimele commit-uri.
- Nu au fost efectuate teste end-to-end cu două conturi autentificate.
- OAuth Google/Apple și e-mailurile de confirmare/resetare depind de configurarea furnizorilor și șabloanelor în Supabase.
- Dictarea vocală depinde de suportul browserului și permisiunea microfonului.
- Prețurile online nu sunt integrate; nu se folosesc API-uri plătite sau surse fără drepturi de reutilizare confirmate.

Acest document separă funcțiile existente de verificările care încă trebuie executate. Nu reprezintă o certificare de lansare.
