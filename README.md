# ListACT

Aplicație de liste de cumpărături pentru gospodării și familii.

## Stadiul dezvoltării

Vezi [raportul detaliat de implementare și verificare](docs/DEVELOPMENT_STATUS.md) pentru funcțiile existente, starea securității, migrațiile și testele încă necesare.

- Ramura de dezvoltare: `develop`
- Ramura `main` este rezervată lansării unice de producție.
- Aplicația nu este încă publicată.
- Migrațiile Supabase se păstrează în `supabase/migrations`.

## Tehnologii

- React + TypeScript + Vite
- Supabase Auth, PostgreSQL, Row Level Security și Realtime
- GitHub Actions pentru verificarea build-ului

## Rulare locală

1. Instalează Node.js 22 sau o versiune compatibilă cu Vite 7.
2. Clonează repository-ul și selectează ramura `develop`.
3. Copiază `.env.example` în `.env.local`.
4. Instalează dependențele și pornește aplicația:

```bash
npm install
npm run dev
```

Build de verificare:

```bash
npm run build
```

## Configurare Supabase

Variabilele frontend necesare sunt:
- `VITE_SUPABASE_URL`
- `VITE_SUPABASE_PUBLISHABLE_KEY`

Cheia publishable este destinată aplicației client și este protejată prin RLS. Nu adăuga niciodată `service_role`, chei secrete sau parole în frontend, în fișiere versionate ori în variabile `VITE_*`.

Pentru autentificarea OAuth trebuie configurate separat Google și Apple în Supabase și în consolele furnizorilor. Până la configurarea lor, autentificarea cu e-mail/parolă rămâne fluxul de bază.

## Funcționalități deja implementate

- autentificare cu e-mail/parolă și inițiere OAuth;
- gospodării multiple, membri și linkuri de invitație;
- liste multiple, redenumire și arhivare;
- produse, cantități, unități și stare cumpărat/ne-cumpărat;
- adăugare individuală și în masă, cu confirmare;
- dictare vocală română prin Web Speech API atunci când browserul o suportă;
- preț personal pe linia produsului, păstrat separat de viitoarele estimări online;
- magazine globale și magazine proprii gospodăriei;
- atribuirea magazinelor în masă;
- sincronizare Realtime pentru produsele listelor.

## Limitări cunoscute

- Web Speech API nu este disponibil în toate browserele și poate depinde de serviciile browserului. Există introducere manuală ca alternativă.
- Invitațiile generează linkuri care se trimit manual; nu este configurat un furnizor de e-mail.
- Login Google/Apple necesită configurarea credențialelor OAuth.
- Nu există încă un furnizor de prețuri online care să îndeplinească simultan cerința de acces continuu gratuit și drepturile explicite de reutilizare. Detalii în [documentarea cercetării surselor](docs/PRICE_DATA_SOURCE_RESEARCH.md).
- Niciun preț online nu este afișat dacă nu există o observație verificată.

## Securitate

- Datele gospodăriilor sunt separate prin RLS.
- Identificatorul gospodăriei selectate în interfață nu este considerat autorizare.
- Cheile privilegiate nu se expun clientului.
- Acceptarea invitației verifică tokenul, expirarea și potrivirea adresei de e-mail.
