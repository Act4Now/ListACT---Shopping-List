# Pregătirea publicării ListACT

Acest ghid pregătește publicarea fără să aleagă în locul proprietarului un furnizor de hosting și fără să publice aplicația.

## Configurația aplicației

Aplicația este un SPA React + Vite. Comanda de build este `npm run build`, iar directorul rezultat este `dist/`.

Setează în mediul de build al hostingului următoarele variabile:

- `VITE_SUPABASE_URL` — URL-ul proiectului Supabase ListACT.
- `VITE_SUPABASE_PUBLISHABLE_KEY` — cheia publishable a proiectului Supabase.

Valorile de referință pentru proiectul actual sunt păstrate în `.env.example`. Cheia publishable este destinată clientului și nu este un secret privilegiat. Nu introduce niciodată `service_role`, chei Supabase secrete sau parole în variabile cu prefixul `VITE_`.

## Cerințe pentru hosting

- Build command: `npm run build`
- Output / publish directory: `dist`
- Runtime Node pentru build: Node.js 22
- Configurează fallback SPA: cererile pentru rute care nu corespund fișierelor statice trebuie servite prin `/index.html`.
- Activează HTTPS și folosește domeniul canonic ales pentru aplicație.

Nu există încă un furnizor de hosting sau un domeniu ales în repository. Nu adăuga reguli specifice Vercel, Netlify, Cloudflare Pages sau altui furnizor până când acesta nu este ales.

## Configurarea Supabase Auth după alegerea domeniului

În Supabase Dashboard → Authentication → URL Configuration:

1. Setează **Site URL** la originea domeniului public final, de exemplu `https://domeniul-ales.ro`.
2. Adaugă la **Redirect URLs** domeniul public și variantele strict necesare pentru callback-urile folosite de aplicație.
3. Nu lăsa URL-uri de preview sau localhost în lista de producție decât dacă sunt necesare și controlate.

Pentru Google sau Apple, configurează separat providerul în Supabase Dashboard → Authentication → Providers și în consola furnizorului respectiv. Nu activa butoanele ca funcționale în producție până când callback URL-urile și credențialele sunt verificate.

## E-mailuri de autentificare

Înainte de lansare, configurează un serviciu SMTP / sender pentru e-mailurile de confirmare și recuperare a parolei și verifică domeniul expeditorului. Nu presupune că setările implicite de e-mail sunt suficiente pentru trafic de producție.

## Baza de date și migrări

- Cele 20 de migrări din istoricul Supabase sunt acum reprezentate în `supabase/migrations` pe `develop`.
- Nu rula migrările istorice din nou pe proiectul Supabase activ.
- Pentru verificarea unei instalări de la zero, folosește un proiect Supabase separat, temporar, și aplică acolo întregul istoric în ordine.
- Nu folosi cheia `service_role` în frontend sau în fișiere versionate.

## Starea publicării

Nicio publicare nu a fost pornită. Ramura `main` nu a fost modificată. Alegerea domeniului și a furnizorului de hosting, adăugarea variabilelor de mediu și configurarea URL-urilor Auth rămân pași necesari înainte de publicare.
