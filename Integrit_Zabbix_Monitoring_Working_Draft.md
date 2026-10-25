# Monitoring Integrit v Zabbixu: pracovní verze

| Položka | Hodnota |
|---|---|
| Dokument | Katalog monitoringových služeb: analýza, návrh platformy a návrhy jednotlivých služeb |
| Verze | Pracovní verze 1 |
| Datum | 15. 10. 2026 |
| Stav | K revizi ve společnosti Integrit |
| Podklady | Katalog v1.0 (`Katalog_monitoringovych_sluzeb_Integrit`) a v1.1 (`Katalog_monitoringovych_sluzeb_integrit_v1.1`, interní a zákaznický Word) |

Toto je jediný pracovní dokument projektu monitoringu. Nahrazuje dříve vytvořené samostatné soubory analýzy.

## Obsah

- **Část 1 · Přehled**
    - 1.1 Co dokument obsahuje
    - 1.2 Co chce Integrit vybudovat
    - 1.3 Dosud přijatá rozhodnutí
    - 1.4 Hlavní doporučení
    - 1.5 Přehled služeb
    - 1.6 Rozhodnutí, která odblokují nejvíc práce
- **Část 2 · Revize katalogu v1.0 a v1.1**
    - 2.1 Jak rozumíme rozsahu
    - 2.2 Čím se v1.1 liší od v1.0
    - 2.3 Mezery, nesrovnalosti a otázky
- **Část 3 · Návrh platformy**
    - 3.1 Architektura platformy
    - 3.2 Konektivita
    - 3.3 Alerting dnes a cesta k Microsoft Planneru
    - 3.4 Měsíční reporting pro zákazníky
- **Část 4 · Služby katalogu**
    - 4.1 MON-SRV · Monitoring serveru
    - 4.2 MON-VIRT · Monitoring virtualizační platformy
    - 4.3 MON-NAS · Monitoring NAS a datového úložiště
    - 4.4 MON-BKP · Monitoring zálohování
    - 4.5 SRV-RESTORE · Ověření obnovitelnosti záloh
    - 4.6 MON-NET · Monitoring firewallu, routeru, VPN a internetu
    - 4.7 MON-LAN · Monitoring switchů, Wi-Fi a PoE
    - 4.8 MON-UPS · Monitoring UPS a napájení
    - 4.9 MON-WEB · Základní monitoring webu
    - 4.10 MON-DNS · Monitoring domény, DNS a certifikátu
    - 4.11 MON-WP · Rozšířený monitoring WordPressu
    - 4.12 MON-WEB-FUNC · Funkční monitoring webu a formulářů
    - 4.13 MON-EPS · Monitoring endpoint security
    - 4.14 MON-M365 · Monitoring Microsoft 365 a licencí
    - 4.15 MON-VOIP · Monitoring telefonní ústředny a VoIP
    - 4.16 MON-CUSTOM · Monitoring vlastní aplikace nebo integrační úlohy
- **Část 5 · Doplňkové služby (návrhy)**
    - 5.1 Doporučení na jedné stránce
    - 5.2 Navržené balíčky
    - 5.3 Průřezové body návrhu
    - 5.4 Zvážené a nenavržené (pro první vydání)
    - 5.5 Potřebná rozhodnutí
    - 5.6 Podrobnosti služeb
- **Část 6 · Pracnost, zavedení, rizika a rozhodnutí**
    - 6.1 Základ platformy (dnes v katalogu chybí)
    - 6.2 Produktizace jednotlivých služeb (první výrobce/platforma)
    - 6.3 Doporučené pořadí zavádění
    - 6.4 Hlavní rizika
    - 6.5 Potřebná rozhodnutí (souhrn)
    - 6.6 Celkový obraz včetně doplňkových služeb
- **Příloha · Zdroje a poznámky k ověření**

# Část 1 · Přehled

## 1.1 Co dokument obsahuje

| Část | Obsah |
|---|---|
| 1 · Přehled | Rozsah, dosud přijatá rozhodnutí, hlavní doporučení a přehled služeb |
| 2 · Revize katalogu | Co říkají verze katalogu v1.0 a v1.1, čím se liší a co je potřeba opravit |
| 3 · Návrh platformy | Architektura a multi-tenancy, konektivita, alerting a Planner, reporting |
| 4 · Služby katalogu | 16 služeb katalogu, každá se zákaznickým pohledem, obchodním pohledem a úplným technickým návrhem |
| 5 · Doplňkové služby | 17 navržených nových služeb ve stejném formátu a návrh balíčků |
| 6 · Pracnost, zavedení, rizika a rozhodnutí | Hodiny, pořadí zavádění, rizika a všechna otevřená rozhodnutí v jednom seznamu |
| Příloha | Zdroje, poznámky k ověření a konvence |

## 1.2 Co chce Integrit vybudovat

**Produktizovaný katalog monitoringových služeb**, které Integrit prodává zákazníkům za jednotku a měsíc (server, zařízení, úloha, doména, tenant…), poskytovaný z **jednoho centrálního multi-tenant serveru Zabbix**. Každá služba je popsána ze tří pohledů: pro zákazníka, obchodně a technicky.

**Model služby**
- Monitoring = **sběr dat, vyhodnocení stavu a upozornění**. Odstranění problému, správa, aktualizace a incident response jsou samostatná servisní vrstva a nejsou součástí ceny monitoringu.
- **Monitoring bez správy:** upozornění dostane určený kontakt zákazníka.
- **Monitoring se správou Integrit:** upozornění vstoupí do servisního procesu Integritu jako tiket (úkol v Microsoft Planneru).

**Stupnice rizika** (z v1.0; v1.1 používá barvy bez definice):

| | Úroveň | Význam |
|---|---|---|
| 🟢 | Nízké | Omezený dopad bez přerušení důležitého provozu |
| 🟡 | Střední | Zhoršení provozu nebo riziko budoucího výpadku |
| 🟠 | Vysoké | Významný výpadek, omezení práce nebo bezpečnostní problém |
| 🔴 | Kritické | Ztráta dat, odstavení klíčových služeb nebo závažný incident |

## 1.3 Dosud přijatá rozhodnutí

| Oblast | Rozhodnutí (Asmir, 15. 10. 2026) |
|---|---|
| Platforma | Jeden centrální multi-tenant server Zabbix, verze **7.0.31** |
| Alerting dnes | E-mail přes Microsoft Graph na **monitoring@integrit.cz** |
| Cíl pro tikety | **Microsoft Planner**, interní tiketovací řešení Integritu pro zákazníky |
| Nástroj pro reporting | Zatím žádný; varianty a doporučení jsou v kapitole 3.4 |
| Výrobci pro první vydání | Neurčeni; rozhodne se po této analýze |
| Konektivita | Navrhuje tato analýza (kapitola 3.2) |
| Doplňkové služby | Navrženy v samostatné části (Část 5) |
| Struktura Planneru | Jeden společný plán, každý zákazník má vlastní bucket |

## 1.4 Hlavní doporučení

| Oblast | Doporučení | Kde |
|---|---|---|
| Verze Zabbixu | Zůstat na 7.0.31. Oficiální sada šablon pro 7.0 už pokrývá Veeam, zdraví a využití Microsoft 365, Proxmox, webové kontroly přes prohlížeč, Acronis, FortiGate, Meraki, APC, iDRAC/iLO, Azure/AWS a další. Vlastní šablony Integritu stavět jen pro mezery (Hyper-V, Synology/QNAP, licence M365, WordPress). Upgrade na 8.0 LTS přibližně v polovině roku 2027 | 3.1.1 |
| Multi-tenancy | Skupiny hostů `Customers/<CUST>/<SITE>`; povinné značky (tagy) `customer`, `site`, `service`, `managed`, `tier`; jedinečné názvy hostů `<CUST>-<SITE>-<název>`; jedna obalová šablona Integritu na službu s ID služby jako tagem; prahy jako makra (globální → šablona → host) | 3.1.3–3.1.4 |
| Onboarding | Evidence zákazníků jako jediný zdroj pravdy a malý nástroj nad API, který vytváří hosty, tagy, SLA služby a podklady pro fakturaci; autoregistrace agentů vázaná na proxy zákazníka | 3.1.5 |
| Konektivita | **Zabbix proxy v každé lokalitě zákazníka** (pouze odchozí TLS, ukládá data při výpadku, dosáhne na SNMP/API/trapy), **centrální proxy pro externí kontroly** webu, DNS a cloudových API a **vstupní (ingress) proxy** pro cloudové servery. Server není nikdy vystaven do internetu. VPN jen jako výjimka | 3.2 |
| Alerting nyní | Zpevnit webhook pro e-mail přes Graph (autentizace certifikátem, Mail.Send omezené na jednu schránku, triggery na selhání, strukturované předměty). Akce řízené tagy připravit hned, aby pozdější směrování bylo jen přidáním akcí. Omezení šumu ještě před jakoukoli automatizací | 3.3.1 |
| Planner | Proveditelné přes Graph v režimu aplikace (`Tasks.ReadWrite.All`). Úkoly zakládat do stávajícího společného plánu, do bucketu daného zákazníka podle tagu `customer`. Začít webhookem ze Zabbixu, který zakládá úkoly přímo; při zhruba 10 a více spravovaných zákaznících přejít na malý mezikus v Azure Function. Pozor na limit 9 000 úkolů na celý plán (sdílí ho všichni zákazníci i ruční tikety), limit 200 bucketů a na to, že Planner nesleduje SLA | 3.3.2 |
| Reporting | Zapnout SLA modul Zabbixu hned (zpětně reportovat neumí). Postavit **vlastní generátor reportů nad API Zabbixu**: jeden firemně brandovaný český PDF report na zákazníka, doručený e-mailem přes Graph a archivovaný v SharePointu. Grafana a Power BI volitelně později | 3.4 |
| Služby | Každá služba je v Části 4 navržena se zákaznickým pohledem, obchodním pohledem, zdroji dat, triggery a prahy, předpoklady, obsahem reportu, variantami výrobců a pracností | Část 4 |
| Doplňkové služby | 17 návrhů ve třech vlnách; Vlna A (hardware serverů, databáze, Active Directory, pošta, prostředí serverovny, interní certifikáty) hned po pilotu | Část 5 |
| Pracnost | Základ platformy **270–450 h** (v katalogu není) + služby katalogu **395–795 h** (katalog uvádí ~200–490 h) + doplňkové služby **450–800 h**. Rozsah pilotu **400–640 h** | Část 6 |
| Zavedení | Základ → pilot se 2–3 zákazníky (web, DNS, servery, zálohování, UPS, internetová brána) → hloubka infrastruktury → cloudové a specializované služby → doplňkové služby po vlnách | 6.3 |

## 1.5 Přehled služeb

**Služby katalogu (Část 4)**

| # | ID | Služba | Riziko | Jednotka | Cena / měsíc (Kč) |
|---|---|---|---|---|---|
| 4.1 | MON-SRV | Monitoring serveru | 🟠 | server | 300–600 |
| 4.2 | MON-VIRT | Monitoring virtualizační platformy | 🔴 | host / platforma | 500–1 200 za host |
| 4.3 | MON-NAS | Monitoring NAS a datového úložiště | 🔴 | zařízení | 300–700 |
| 4.4 | MON-BKP | Monitoring zálohování | 🔴 | zálohovací úloha | 150–300 |
| 4.5 | SRV-RESTORE | Ověření obnovitelnosti záloh (servisní služba) | 🔴 | test / plán | individuálně |
| 4.6 | MON-NET | Monitoring firewallu, routeru, VPN a internetu | 🟠 | zařízení / lokalita | 300–800 |
| 4.7 | MON-LAN | Monitoring switchů, Wi-Fi a PoE | 🟡–🟠 | switch / AP | 200–500 / 100–250 |
| 4.8 | MON-UPS | Monitoring UPS a napájení | 🔴 | UPS | 200–500 |
| 4.9 | MON-WEB | Základní monitoring webu | 🟡 | web | 100–200 |
| 4.10 | MON-DNS | Monitoring domény, DNS a certifikátu | 🟠 | doména | 50–150 |
| 4.11 | MON-WP | Rozšířený monitoring WordPressu | 🟠 | instalace | 300–500 |
| 4.12 | MON-WEB-FUNC | Funkční monitoring webu a formulářů | 🟠 | scénář | 200–800 |
| 4.13 | MON-EPS | Monitoring endpoint security | 🟠 | endpoint / tenant | 20–60 za endpoint, min. 300–800 |
| 4.14 | MON-M365 | Monitoring Microsoft 365 a licencí | 🟡 | tenant | 300–1 500 |
| 4.15 | MON-VOIP | Monitoring telefonní ústředny a VoIP | 🟠 | ústředna | 300–1 000 |
| 4.16 | MON-CUSTOM | Monitoring vlastní aplikace nebo integrační úlohy | 🟡–🔴 | kontrola | 200–1 000 |

**Doplňkové služby (Část 5)**: MON-HW, MON-DB, MON-AD, MON-MAIL, MON-ENV, MON-CERT (Vlna A); MON-IDSEC, MON-CLOUD, MON-ROLE, MON-SECEVT, MON-EXPOSURE, MON-MDM, SRV-SHUTDOWN, MON-LIFECYCLE (Vlna B); MON-CCTV, MON-PRINT, MON-CONT (Vlna C). Podrobnosti a ceny jsou v kapitole 5.1.

## 1.6 Rozhodnutí, která odblokují nejvíc práce

1. **Kde poběží centrální platforma a externí proxy** (vlastní datacentrum, nebo cloud).
2. **Proxy v lokalitě jako standard** plus jednorázový poplatek za připojení lokality.
3. **Výrobci pro první vydání**, podle počtu výskytů u zákazníků Integritu pro každou službu (virtualizace, zálohování, firewall, switch/Wi-Fi, NAS, ústředna, endpoint security).

Úplný seznam otevřených rozhodnutí je v kapitolách 6.5 a 5.5.

# Část 2 · Revize katalogu v1.0 a v1.1

Revidováno 15. 10. 2026. Podklady: `Katalog služeb/v1.0/` (md + docx) a `Katalog služeb/v1.1/` (md + interní docx + zákaznický docx). Oba soubory verze v1.0 mají stejný obsah. Oba wordové soubory verze v1.1 jsou generovány z markdownu v1.1.

## 2.1 Jak rozumíme rozsahu

Integrit chce **produktizovaný katalog monitoringových služeb postavených na Zabbixu**, které může prodávat zákazníkům za jednotku a měsíc. Každá služba je popsána třemi způsoby: pro zákazníka, z obchodního pohledu a technicky.

**Model služby.** Monitoring znamená *sběr dat, vyhodnocení stavu a upozornění*. Odstranění problému je samostatná servisní vrstva. Služba se dodává ve dvou režimech:
- **Monitoring bez správy:** upozornění dostane určený kontakt zákazníka.
- **Monitoring se správou Integrit:** upozornění vstoupí do servisního procesu Integritu, typicky jako tiket.

**16 služeb** (ID podle v1.1), seskupených tak, jak je čtu:

| Skupina | ID | Služba | Riziko | Jednotka | Cena/měsíc (Kč) | Hlavní metoda v Zabbixu |
|---|---|---|---|---|---|---|
| Infrastruktura | MON-SRV | Server (OS, CPU, RAM, disky, služby, plánované úlohy, logy) | Vysoké | server | 300–600 | Agent 2, SNMP/API |
| | MON-VIRT | Virtualizace (hostitelé, clustery, VM, datastory) | Kritické | hostitel/platforma | 500–1 200 za hostitele | Nativní VMware, API |
| | MON-NAS | NAS / úložiště (RAID, disky, zdroje, teploty) | Kritické | zařízení | 300–700 | SNMPv3/API přes proxy |
| | MON-UPS | UPS a napájení | Kritické | UPS | 200–500 | SNMPv3 přes proxy |
| Ochrana dat | MON-BKP | Výsledky zálohovacích úloh, chybějící běhy | Kritické | zálohovací úloha | 150–300 | API/e-mail/syslog → parser → zabbix_sender, `nodata()` |
| | SRV-RESTORE | Testování obnovy | Kritické | test/plán | individuálně | Skriptovaná obnova + report (služba, ne monitoring) |
| Síť | MON-NET | Firewall, router, WAN, VPN, failover | Vysoké | zařízení/lokalita | 300–800 | SNMPv3, ICMP, TCP, syslog, závislosti |
| | MON-LAN | Switche, Wi‑Fi AP, PoE | Střední–Vysoké | switch / AP | 200–500 / 100–250 | SNMPv3, API kontroléru, LLD |
| Web a internet | MON-WEB | Dostupnost webu, odezva, TLS certifikát | Střední | web | 100–200 | Webový scénář / HTTP agent |
| | MON-DNS | Expirace domény, DNS záznamy, certifikát | Vysoké | doména | 50–150 | RDAP/WHOIS, DNS kontroly |
| | MON-WP | Aktualizace jádra/pluginů WordPressu, WP-Cron | Vysoké | instalace | 300–500 | Vlastní endpoint WP pluginu + HTTP agent |
| | MON-WEB-FUNC | Funkční testy webu/formulářů | Vysoké | scénář | 200–800 | Webový scénář, headless prohlížeč |
| Bezpečnost a SaaS | MON-EPS | Ochrana koncových stanic (např. ESET Protect): poslední spojení, ochrana, hrozby | Vysoké | koncová stanice/tenant | 20–60 za stanici, min. 300–800 | API/report konzole |
| | MON-M365 | Licence Microsoft 365 a stav tenantu | Střední | tenant | 300–1 500 | Microsoft Graph |
| Telefonie | MON-VOIP | Ústředna, SIP trunky, registrace | Vysoké | ústředna | 300–1 000 | SNMP, API, SIP OPTIONS |
| Na míru | MON-CUSTOM | Kontroly vlastních aplikací / integračních úloh | Nízké–Kritické | kontrola | 200–1 000 | UserParameter, log, DB, trapper |

Navržená pilotní sada podle v1.0: **Web Basic, Doména/SSL, Server, Záloha, UPS**.

**Jak chápu záměr:** jde o katalog tažený obchodem, zatím ne o technický návrh. Technické kapitoly jmenují správné stavební prvky Zabbixu, ale popisují přístup, nikoli konkrétní šablony, položky (items), prahy či architekturu. To odpovídá vašemu plánu udělat jako další krok technický rozbor jednotlivých služeb.

## 2.2 Čím se v1.1 liší od v1.0

Changelog v1.1 uvádí, že rozsah všech služeb se nemění a sjednotila se jen struktura, zákaznické formulace a metadata. To je z velké části pravda, ale v1.1 zároveň **přišla o detaily**, které bude technická fáze potřebovat.

### Přidáno ve v1.1
- Metadata katalogu (verze 1.1, 14. 10. 2026, stav *ke schválení*) a historie katalogu.
- **ID služby** pro každou službu (MON-SRV, MON-VIRT, ...) a k tomu verze, stav a historie změn každé služby.
- Jeden markdownový soubor je nyní **jediným zdrojem** pro dva wordové výstupy: interní (všechny tři části) a zákaznický (jen zákaznická část). Zákaznický wordový soubor byl zkontrolován: neobsahuje ceny, pracnost ani technický obsah.
- Pevná zákaznická část u každé služby: „Účel“, pole rozsahu a standardní odstavec „Důležitá hranice“, který říká, že odstranění problémů, správa, aktualizace a incident response nejsou součástí.
- Výslovné uvedení, že oprava, správa, aktualizace a incident response **nejsou** součástí ceny monitoringu.
- Seznam **Otevřených bodů**: balíčky a minimální měsíční cena, standard konektivity (Proxy, VPN nebo obojí), podporované platformy a výrobci pro první vydání, směrování upozornění a proces tiketů a **přesné prahy alarmů, SLA a doba uchování reportů**.
- Ceny a pracnost jsou nyní označeny jako *odhady*.
- Standardní technická kostra u každé služby (komunikační tok, konektivita, konfigurace Zabbixu, podmínky otevření/uzavření alarmu, falešné poplachy, předání upozornění).

### Odstraněno nebo oslabeno ve v1.1
- **Definice stupnice rizika** (Nízké / Střední / Vysoké / Kritické) zmizely. Emoji zůstala, ale už nejsou definována.
- **Souhrnná obchodní matice** (všechny služby v jedné tabulce) zmizela.
- **„Body k rozhodnutí s kolegy“** včetně seznamu pilotních produktů zmizely. Většina se přesunula do Otevřených bodů, ale **pilotní seznam a otázka „jeden společný report, nebo reporty po službách“** ne.
- **Šablona pro přidání nové služby** zmizela.
- **Konkrétní technické detaily byly nahrazeny obecnou šablonovitou formulací.** Příklady:
  - Server: vypadly SMART, NTP a seznam alarmů (nedostupnost, plný disk, zastavená služba, opakovaná chyba, neúspěšná úloha). Z monitorovaných oblastí vypadly i „aktualizace“, přestože „rozsah se nemění“.
  - UPS: vypadly pojmenované triggery (provoz na baterii, slabá baterie, výměna baterie, přetížení, kritická doba výdrže).
  - Záloha: zkrácen seznam položek (stav, doba trvání, velikost, text chyby, čas posledního výsledku, `nodata()`).
  - DNS: vypadly `not_after` certifikátu, řetězec a shoda hostname.
  - Virtualizace: vypadla „nativní integrace Zabbixu s VMware“ a závislosti hostitel–VM.
  - Síť: vypadly chyby/zahozené pakety na rozhraních, provoz, CPU/RAM/teplota.
  - Pole „Komunikační tok“, „Konektivita“, „Konfigurace Zabbixu“, „Podmínky alarmu“ a „Falešné poplachy“ mají u všech 16 služeb shodný text, takže zatím nic neříkají.
- **Obchodní detaily nahrazeny šablonovitým textem.** „Typický zákazník“ je u všech služeb stejná věta a „Obchodní potenciál“ už nemá hodnocení z v1.0 (vysoký, velmi vysoký atd.). Verze v1.0 jmenovala jako cílové VMware/Hyper-V a ESET Protect; v1.1 ne.
- Interní wordový soubor je popsán jako soubor s otevřenými body a historií, ale **neobsahuje** ani jednu z těchto částí. Z technické části navíc ukazuje jen „Návrh řešení“ a „Předání upozornění“.

**Shrnutí:** v1.1 je lepší *dokument* (ID, verzování, čisté oddělení zákaznické a interní části). v1.0 je lepší *technický výchozí bod*. Pro technickou fázi bych jako kostru použil v1.1 a konkrétní detaily do ní vrátil z v1.0.

## 2.3 Mezery, nesrovnalosti a otázky

### Nesrovnalosti k opravě v katalogu
1. **SRV-RESTORE v zákaznickém textu** používá standardní úvod „tato služba průběžně monitoruje...“, přestože její vlastní omezení říká, že jde o servisní test, ne průběžný monitoring. Navíc je zařazena do rodiny MON- s ID SRV-; možná patří do samostatné kapitoly „služby“.
2. **Zákaznický wordový soubor má podtitul „Zákaznický katalog | interní pracovní verze“**. Toto označení se nesmí dostat k zákazníkům.
3. **Wi‑Fi AP** byl v matici v1.0 samostatný řádek (vlastní riziko, vlastní pracnost „na kontrolér“, nasazení 0,25–1 h), v těle je ale sloučen do MON-LAN. Je třeba rozhodnout, zda budou AP samostatná položka (SKU).
4. **„Aktualizace“ serveru** se ve v1.0 monitorovaly a ve v1.1 tiše vypadly. Potvrďte, zda je stav záplat v rozsahu.
5. Emoji rizika jsou ve v1.1 použita bez definované stupnice.

### Otázky k platformě a architektuře (potřeba před technickým návrhem)

*Stav: zodpovězeno rozhodnutími v kapitole 1.3 a návrhem platformy v Části 3.*
6. **Platforma Zabbix:** jaká verze (6.0 LTS, 7.0 LTS, 7.x)? Jeden centrální multi-tenant server, nebo instance pro každého zákazníka? Kde bude hostován?
7. **Standard konektivity:** v1.0 se kloní k Zabbix Proxy v každé lokalitě zákazníka se šifrovaným odchozím spojením; v1.1 to nechává otevřené. Toto rozhodnutí určuje pracnost nasazení téměř každé služby.
8. **Multi-tenancy:** jak se oddělují zákazníci (skupiny hostů, skupiny uživatelů, oprávnění, směrování upozornění podle tagů) a zda zákazníci dostanou přístup do frontendu Zabbixu, nebo jen reporty.
9. **Alerting:** jaké kanály (e-mail, SMS, Teams, telefon), jaký tiketovací systém pro režim „se správou“ a zda alerting běží 24/7, nebo v pracovní době.
10. **Reporting:** měsíční reporty jsou uvedeny u každé služby. Jakým nástrojem se budou tvořit (SLA a plánované reporty Zabbixu, Grafana, vlastní řešení) a bude to jeden souhrnný report na zákazníka, nebo jeden na službu?
11. **SLA, prahy a doba uchování** jsou uvedeny jako otevřené. Chcete výchozí profily prahů pro každou službu s možností přepsání pro jednotlivé zákazníky?

### Technické otázky k jednotlivým službám (upozorňuji nyní, detail později)
12. **MON-VIRT:** VMware je v Zabbixu nativně; Hyper-V a Proxmox ne a potřebují agenta/skripty nebo komunitní šablony. Které platformy budou v prvním vydání?
13. **MON-BKP:** které zálohovací produkty nejdřív (Veeam, Synology, Windows Server Backup, jiné)? Cesta přes parser + `zabbix_sender` je vlastní práce pro každý produkt zvlášť.
14. **MON-WP:** vyžaduje vývoj a údržbu vlastního pluginu pro WordPress. Je to záměr, nebo se má použít existující endpoint/plugin?
15. **MON-EPS:** v prvním vydání jen ESET Protect, nebo i další?
16. **MON-M365:** monitoring licencí přes Graph je jasný; „vybrané stavy tenantu“ nejsou definovány.
17. **MON-WEB-FUNC:** kontroly přes headless prohlížeč jsou mimo nativní Zabbix a vyžadují externí spouštěč. Potvrďte, že je to přijatelné.
18. **MON-VOIP:** kteří výrobci ústředen?

### Pravděpodobně chybějící služby

*Stav: rozpracováno jako návrhy v Části 5.*
Tyto oblasti jsou u stejného okruhu zákazníků běžné a nejsou ani v jedné verzi. Uveďte, zda některé přidat, nebo zda jsou záměrně mimo rozsah:
- Monitoring databází (MS SQL, MySQL/MariaDB, PostgreSQL).
- Active Directory / řadiče domény a Entra ID.
- Out-of-band správa hardwaru serverů (iDRAC, iLO, IPMI, Redfish), odlišná od monitoringu OS.
- Tok pošty / poštovní server.
- Tiskárny, kamery/NVR, senzory prostředí (teplota, vlhkost v serverovnách).
- Prostředky veřejného cloudu (Azure, AWS).


# Část 3 · Návrh platformy

Sdílená platforma Zabbix, na které běží všechny služby z Částí 4 a 5.


## 3.1 Architektura platformy

Rozsah: sdílená platforma Zabbix, na které běží všechny služby katalogu. Výchozí stav: **jeden centrální multi-tenant server Zabbix, verze 7.0.31**.

### 3.1.1 Strategie verzí

| Fakt | Důsledek |
|---|---|
| 7.0 LTS: plná podpora do **30. 6. 2027**, omezená (bezpečnostní) podpora do **30. 6. 2029** ([životní cyklus Zabbixu](https://www.zabbix.com/cz/life_cycle_and_release_policy)). | 7.0.31 je bezpečný produkční základ minimálně na dalších 18 měsíců. |
| 8.0 LTS je plánována na Q4 2026; beta 2 vyšla v červenci 2026 ([everywan](https://everywan.com/en/blog/zabbix-8-0-what-actually-changes)). | Přechod na 8.0 je vhodné naplánovat přibližně na polovinu roku 2027, po prvních opravných vydáních. |
| Oficiální sada šablon `release/7.0` (ověřeno v Git repozitáři Zabbixu, commit ze 14. 10. 2026) už obsahuje šablony, které tento katalog potřebuje nejvíc: *Microsoft 365 reports by HTTP*, *Veeam Backup & Replication by HTTP*, *Veeam Backup Enterprise Manager by HTTP*, *Proxmox VE by HTTP*, *Website by Browser*, *Acronis Cyber Protect Cloud*, *Asterisk by HTTP*, *FortiGate by HTTP/SNMP*, *Cisco Meraki by HTTP*, *TrueNAS/OPNsense/pfSense by SNMP*, rodinu APC UPS, HPE iLO / Dell iDRAC (Redfish), Azure a AWS. Stránky integrací na zabbix.com uvádějí požadavek *nejnovější* větve (7.4+), což je pro 7.0 zavádějící. Ve verzi 7.0 stále chybí: Hyper-V, Synology/QNAP, inventura licencí M365. Nativní OAuth pro e-mailový typ média existuje až od 7.4. | Většina služeb může začít na oficiálních šablonách 7.0. Šablony vyvinuté Integritem jsou potřeba jen pro mezery. |

**Doporučení:** pilot provozovat na 7.0.31 s oficiálními šablonami 7.0 (obalenými, viz 1.4) a šablonami Integritu jen pro mezery. Ty stavět jako **přenositelné**: čistý HTTP agent, Script a závislé položky, žádné funkce z 7.2+. Na 8.0 LTS přejít po jejích prvních opravných vydáních, přibližně v polovině roku 2027, kvůli delší podpoře, ne kvůli šablonám. Všechny šablony Integritu držet v Gitu (export YAML), aby se upgrade dal otestovat na stagingovém serveru.

### 3.1.2 Topologie serveru

```
                    ┌───────────── Integrit DC / cloud ─────────────┐
 Customer site A    │                                                │
 ┌──────────────┐   │  Ingress proxy group (DMZ, 2+ proxies)        │
 │ Site proxy A │──TLS──►  ◄── internet agents (cloud VMs, roaming)  │
 └──────────────┘   │           │                                    │
 Customer site B    │           ▼                                    │
 ┌──────────────┐   │  Zabbix server HA (node 1 active, node 2 stby) │
 │ Site proxy B │──TLS──►  PostgreSQL + TimescaleDB (replicated)     │
 └──────────────┘   │  Frontend (MFA) · Web service (PDF reports)    │
                    │  External-check proxy group (web, DNS, Graph,  │
                    │  vendor clouds, WebDriver for browser items)   │
                    └────────────────────────────────────────────────┘
```

Komponenty:
- **Zabbix server 7.0.31 s nativním HA** (dva uzly, jeden aktivní). Server není nikdy vystaven do internetu. Komunikují s ním jen proxy ve vlastní síti Integritu.
- **Databáze:** PostgreSQL s **TimescaleDB** (automatické partitionování a komprese historie/trendů). Použít streaming replikaci nebo spravovaný PostgreSQL s obnovou k bodu v čase (point-in-time recovery).
- **Frontend:** za reverzní proxy s TLS. Zapnout vestavěné **MFA (TOTP nebo Duo)** ze 7.0 pro každý účet Integritu, nebo použít SAML s Entra ID a vynutit MFA přes Conditional Access. Preferováno je SAML s Entra ID, protože využívá identitu Integritu.
- **Zabbix web service** (s headless Chrome) jen v případě, že se použijí nativní plánované PDF reporty (viz kapitola 3.4).
- **Skupiny proxy** (novinka 7.0, s automatickým vyvažováním zátěže a failoverem): jedna skupina pro příjem z internetu a jedna pro externí kontroly. Agenti musí mít verzi 7.0+, aby u aktivních kontrol následovali přesměrování skupiny proxy.
- **Buffer proxy:** na všech proxy použít *hybridní* režim bufferu ze 7.0 (nejdřív paměť, při přetečení disk).

#### Dimenzování (výchozí bod; ověřit podle reálného NVPS)

| Měřítko | Hosté | NVPS (přibl.) | Server | DB |
|---|---|---|---|---|
| Pilot | < 300 | < 300 | 4 vCPU / 8 GB | 4 vCPU / 16 GB, 200 GB SSD |
| 1. rok | 300–1 500 | 300–1 500 | 8 vCPU / 16 GB | 8 vCPU / 32 GB, 500 GB SSD |
| Růst | 1 500–5 000 | 1 500–5 000 | 8–16 vCPU / 32 GB | 16 vCPU / 64 GB, 1 TB NVMe |

Úzkým hrdlem je databáze. Historie zůstává v DB, proto plánovat IOPS spíše než CPU. Discovery VMware, které vytváří jednoho hosta na každou VM (MON-VIRT), dokáže počet hostů rychle znásobit.

#### Doba uchování

| Data | Návrh | Důvod |
|---|---|---|
| Historie (surové hodnoty) | 14–31 dní | Stačí pro řešení problémů; tvoří většinu objemu DB. |
| Trendy (hodinové min/prům/max) | 25 měsíců | Meziroční kapacitní trendy v reportech. |
| Události/problémy | 25 měsíců | Historie SLA a incidentů pro roční reporty a spory. |
| Měsíční PDF reporty | Archiv mimo Zabbix (SharePoint), 5+ let | Reporty jsou smluvním záznamem. |

Tyto hodnoty uzavírají otevřený bod katalogu „politika uchování“, pokud smlouva nevyžaduje víc.

### 3.1.3 Model multi-tenancy

Zabbix nemá pevný objekt tenantu. Oddělení se staví ze skupin hostů, skupin uživatelů, tagů a proxy. Níže uvedený model udržuje každého tenanta oddělitelného pro oprávnění, alerting, reporting i offboarding.

#### Skupiny hostů

```
Customers/<CUST>                        e.g. Customers/ACME
Customers/<CUST>/<SITE>                 e.g. Customers/ACME/Praha
Services/<SERVICE-ID>                   e.g. Services/MON-SRV  (cross-tenant view for Integrit)
Integrit/Platform                       Zabbix server, proxies, self-monitoring
Templates/Integrit/<SERVICE-ID>         template groups
```

`<CUST>` je krátký neměnný kód zákazníka, ideálně tentýž kód, který Integrit používá ve fakturaci a v Planneru.

#### Povinné značky (tagy)

Nese je každý host. Tagy na úrovni šablony nesou ID služby, takže ho problémy automaticky dědí.

| Tag | Úroveň | Příklad | Použití |
|---|---|---|---|
| `customer` | host | `ACME` | směrování upozornění, bucket zákazníka v Planneru, filtr reportu, počty pro fakturaci |
| `site` | host | `Praha` | závislosti, seskupení v reportu |
| `service` | šablona | `MON-SRV` | mapování na katalog, směrování, fakturace, reporty |
| `managed` | host | `yes` / `no` | směrování „se správou / bez správy Integrit“ |
| `tier` | host | `standard` / `critical` | eskalace 24/7 vs. v pracovní době |
| `contract` | host | číslo smlouvy nebo objednávky | párování s fakturací |

#### Pojmenování

- Technický název hosta: `<CUST>-<SITE>-<name>` (např. `ACME-PRG-SRV-DC01`). Musí být jedinečný v rámci celého serveru, protože kolize mezi zákazníky jsou klasickou chybou multi-tenant prostředí.
- Viditelný název: srozumitelný pro lidi (`ACME · DC01 (Praha)`).
- Název proxy: `PXY-<CUST>-<SITE>`.

#### Řízení přístupu

- Zaměstnanci Integritu: skupiny uživatelů podle role (NOC čtení/potvrzení, technici čtení i zápis, administrátoři). Filtry oprávnění podle tagů mohou tým omezit například na `service:MON-NET`.
- Přístup zákazníka jen pro čtení (volitelně, později): jedna skupina uživatelů na zákazníka s právem čtení jen na `Customers/<CUST>`. Zákazníci pak vidí *pouze* své vlastní problémy a dashboardy. Je třeba se vyhnout dvěma pastím: globální mapy a globální widget „Problems“ nesmí nikdy odkazovat na skupiny jiných zákazníků a zákazničtí uživatelé dostanou roli *User* bez přístupu k API.
- Autentizace: SAML (Entra ID) pro zaměstnance. Zákaznické účty jsou lokální s MFA, případně hosté Entra B2B, pokud zákazníci přístup někdy dostanou.

#### Počty pro fakturaci

Fakturační jednotky lze odvodit z API: spočítat hosty se `service:MON-SRV` pro každý `customer`, spočítat LLD položky zálohovacích úloh atd. Vznikne tak měsíční fakturační export, který odpovídá jednotkám katalogu, bez ručního počítání.

### 3.1.4 Strategie šablon

1. **Oficiální šablony nikdy neupravovat.** Pro každou službu vytvořit obalovou šablonu Integritu, `INT MON-SRV Windows` nebo `INT MON-UPS Generic UPS-MIB`, která linkuje oficiální šablonu (šablony), přidává tagy, přepisuje makra a přidává položky specifické pro Integrit.
2. **Jedna obalová šablona na kombinaci služba × technologie.** ID služby je tagem šablony, takže každý problém lze přiřadit ke službě katalogu.
3. **Prahy jako makra**, s kontextem (např. `{$VFS.FS.PUSED.MAX.CRIT:"D:"}`), nastavená na třech úrovních: globální výchozí hodnota → šablona → přepsání na hostu pro konkrétního zákazníka. Tím je otevřený bod katalogu „přesné prahy“ vyřešen jako výchozí hodnoty plus přepsání pro zákazníka.
4. **Tajné údaje** (API klíče, hesla SNMPv3, client secrets pro Graph) patří do *tajných maker* (secret macros). Ve střednědobém horizontu použít integraci s trezorem ve 7.0 (HashiCorp Vault nebo CyberArk), aby tajné údaje v DB Zabbixu vůbec nebyly.
5. **Verzovat šablony v Gitu.** Každá změna se exportuje jako YAML, projde revizí a importuje se přes API. Verze šablony odpovídá verzi služby v katalogu (např. MON-SRV 1.1 → tag šablony `version:1.1`).
6. **Konvence závažnosti**, používaná shodně všemi šablonami:

| Závažnost v Zabbixu | Význam | Obdoba rizika v katalogu | Výchozí zpracování |
|---|---|---|---|
| Informace (Information) | Informace, bez akce | – | Bez upozornění; jen v reportu |
| Varování (Warning) | Zhoršení nebo včasné varování | 🟢/🟡 | E-mail, pracovní doba |
| Průměrná (Average) | Služba omezena | 🟡/🟠 | E-mail; tiket po 10 min |
| Vysoká (High) | Výpadek jednoho systému | 🟠 | E-mail + tiket okamžitě |
| Katastrofa (Disaster) | Výpadek lokality nebo více systémů, ohrožení dat | 🔴 | E-mail + tiket + telefon/SMS (úroveň critical) |

### 3.1.5 Automatizace onboardingu

Ruční onboarding neškáluje a vede k chybám v tagování. Návrh:

- **Evidence zákazníků jako jediný zdroj pravdy:** seznam v SharePointu nebo YAML v Gitu pro každého zákazníka s lokalitami, proxy, kontakty, příznakem správy ano/ne, ID bucketu zákazníka ve společném plánu Planneru a hosty podle služeb včetně přepsání maker. Malý nástroj v Pythonu (Zabbix API) z ní vytváří a aktualizuje skupiny hostů, hosty, tagy, makra, okna údržby a skupiny uživatelů. Tentýž nástroj vytváří počty pro fakturaci a úklid při offboardingu.
- **Autoregistrace agentů** pro servery: instalátor Integritu (MSI nebo role Ansible) nastaví `HostMetadata=INT;CUST=ACME;SVC=MON-SRV;OS=windows`. Akce autoregistrace podmíněná **„proxy = PXY-ACME-…“**, aby se host nemohl přihlásit k jinému tenantovi, přidá skupiny, šablony a tagy. Pozor: 7.0 má jeden globální PSK pro autoregistraci. Po registraci nástroj přepne každého hosta na vlastní PSK, nebo se použijí certifikáty.
- **Nasazení proxy:** zabezpečený image (šablona VM / OVA, Hyper-V VHDX, Docker compose) plus role Ansible. Viz kapitola 3.2.

Pracnost této automatizace: 40–60 h. Vrátí se přibližně po 10–15 zákaznících.

### 3.1.6 Monitoring monitoringu

- Oficiální šablony *Zabbix server health* a *Zabbix proxy health* na každé komponentě. Triggery „naposledy viděno“ pro proxy v každé lokalitě zákazníka, které samy o sobě upozorňují, že lokalita zákazníka je nedostupná.
- **Externí dead-man switch:** pokud vypadne server Zabbix nebo cesta e-mailů přes Graph, nikdo upozornění nedostane. Akce v Zabbixu posílá každých 5 minut heartbeat do externí služby (např. Azure Function, Logic App nebo hostovaná kontrola heartbeatu). Pokud heartbeat ustane, tato služba pošle Integritu e-mail nebo SMS.
- Trigger na frontu upozornění a selhání typu média: selhání tokenu pro Graph musí být viditelná.
- Zálohy DB a konfigurace Zabbixu plus test obnovy (používáme vlastní MON-BKP/SRV-RESTORE).

### 3.1.7 Bezpečnost a compliance

- **Žádné vzdálené příkazy.** `EnableRemoteCommands` zůstává vypnuté a `system.run` je na všech agentech zakázán, pokud služba nepotřebuje konkrétní `AllowKey`, například pro skript stavu zálohy. To omezuje možný dopad (blast radius) Integritu v sítích zákazníků.
- **Účty s minimálními oprávněními** všude: API uživatelé jen pro čtení, SNMPv3 authPriv, role vSphere jen pro čtení, aplikace pro Graph jen s uvedenými oprávněními.
- **Zabezpečení proxy:** jen odchozí spojení, automatické bezpečnostní aktualizace, žádná příchozí správa kromě cesty pro správu Integritu. Volitelně Wazuh nebo Defender na proxy.
- **Auditní log** v Zabbixu (ve 7.0 ve výchozím stavu zapnutý) a jeho pravidelná kontrola.
- **Smlouvy:** monitoring sbírá názvy hostů, uživatelská jména v logech a e-mailové adresy. Ke službě by měla být uzavřena smlouva o zpracování osobních údajů. Podle nového českého zákona o kybernetické bezpečnosti (transpozice NIS2) budou zákazníci v jeho působnosti považovat Integrit za významného dodavatele. Pravděpodobně si vyžádají zdokumentovaný bezpečnostní popis monitoringové platformy (tato kapitola). *Přesné povinnosti nechat potvrdit právníkem.*

### 3.1.8 Potřebná rozhodnutí k platformě

1. Hostování centrální platformy: vlastní DC, nebo Azure/jiný cloud (ovlivňuje návrh příjmu z internetu a náklady na HA).
2. Zda zákazníci někdy dostanou přístup do frontendu Zabbixu (určuje, jak striktní musí být RBAC pro jednotlivé zákazníky od prvního dne; doporučení: navrhnout s tím počítat, zapnout později).
3. Umístění evidence zákazníků: seznam v SharePointu, nebo Git.
4. Přijmout plán upgradu na 8.0 LTS přibližně v polovině roku 2027.


## 3.2 Konektivita

Otázka: jak dostat data z prostředí zákazníků na jeden centrální server Zabbix bezpečně, levně a škálovatelně, napříč mnoha zákazníky s překrývajícími se privátními rozsahy IP adres.

### 3.2.1 Co je potřeba zasáhnout

| Zdroj dat | Potřebný směr | Služby |
|---|---|---|
| Zabbix agent na serverech | Agent → kolektor (aktivní režim) | MON-SRV, MON-CUSTOM, části MON-BKP, MON-VIRT (Hyper-V) |
| SNMP / ICMP / TCP na zařízeních v LAN | Kolektor → zařízení uvnitř LAN | MON-NET, MON-LAN, MON-NAS, MON-UPS, MON-VOIP |
| On-prem API (vCenter, Veeam, Proxmox, ústředna, ESET on-prem) | Kolektor → API uvnitř LAN | MON-VIRT, MON-BKP, MON-VOIP, MON-EPS |
| SNMP trapy / syslog | Zařízení → kolektor uvnitř LAN | MON-NET, MON-NAS, MON-UPS, MON-VOIP |
| Veřejné endpointy (weby, DNS, RDAP, certifikáty, veřejné IP zákazníka) | Kolektor v internetu → cíl | MON-WEB, MON-DNS, MON-WEB-FUNC, MON-WP, MON-NET (pohled zvenčí) |
| Cloudová API (Microsoft Graph, ESET Connect, Defender, Meraki…) | Kolektor v internetu → cloud výrobce | MON-M365, MON-EPS, MON-LAN (cloudové kontroléry) |

Některá data lze sbírat jen *uvnitř* LAN zákazníka (SNMP, trapy, on-prem API) a některá jen *zvenčí* (pohled zvenku na web, DNS a WAN). Žádný jednotlivý typ připojení nepokryje obojí.

### 3.2.2 Varianty

#### A. Agenti se připojují přímo na centrální server
Aktivní agenti s TLS (PSK nebo certifikát) se připojují přes internet na server na TCP 10051.
- ✔ Žádná infrastruktura u zákazníka; triviální pro jednotlivé cloudové VM.
- ✘ Pokrývá jen data z agentů: žádné SNMP, trapy, API v LAN ani ICMP.
- ✘ Vystavuje samotný server do internetu.
- ✘ Při výpadcích jen malý buffer (vlastní buffer agenta).
- **Verdikt:** přijatelné jen přes vstupní (ingress) proxy (varianta E), nikdy přímo na server.

#### B. Jedna Zabbix proxy v každé lokalitě zákazníka (aktivní režim)
Malá proxy (VM, kontejner nebo mini-PC) v lokalitě zákazníka otevírá **odchozí** TLS spojení k Integritu (TCP 10051). Dotazuje vše lokální a data předává dál.
- ✔ Jen odchozí spojení. Zákazníci to obvykle přijmou bez úprav firewallu kromě povolení jednoho cíle.
- ✔ Sbírá všechny typy dat z LAN: SNMP v1/2c/3, trapy (přes snmptrapd na proxy), IPMI, VMware, HTTP/API, ODBC, ICMP, agenty a položky prohlížeče ze 7.0.
- ✔ Při výpadcích WAN data ukládá do bufferu (hybridní buffer ve 7.0). Triggery `nodata()` se během nedostupnosti proxy falešně nespouštějí, protože nestriktní `nodata()` nedostupnost proxy ignoruje.
- ✔ Přirozená hranice tenantu. Překrývající se rozsahy IP mezi zákazníky nevadí a autoregistraci lze navázat na proxy.
- ✔ Škáluje horizontálně; zátěž centrálního serveru zůstává nízká.
- ✘ Další systém v každé lokalitě, který je třeba nasadit, záplatovat a držet na stejné hlavní verzi jako server.
- ✘ Potřebuje v lokalitě hostitele: VM na hypervisoru zákazníka nebo malou appliance v lokalitách bez virtualizace.

#### C. Site-to-site VPN z Integritu ke každému zákazníkovi, centrální dotazování
- ✔ Využívá správcovské VPN, které Integrit možná už má.
- ✘ Překrývající se rozsahy RFC 1918 mezi zákazníky vyžadují NAT pro každý tunel, což se rychle stává složitým.
- ✘ Široká síťová důvěra mezi Integritem a každým zákazníkem, což je problém z hlediska bezpečnosti i dodavatelského řetězce podle NIS2.
- ✘ Výpadek VPN znamená, že zákazník je „neviditelný“, bez bufferování.
- ✘ Pravidla firewallu na obou stranách pro každý protokol (SNMP, ICMP, API, porty agentů).
- **Verdikt:** jen jako záložní řešení tam, kde zákazník odmítá jakékoli zařízení Integritu, ale už má spravovanou VPN. I pak umístit proxy na stranu tunelu u Integritu, místo aby server dotazoval přes tunel.

#### D. Centrální proxy pro externí kontroly (v DC Integritu nebo v cloudu)
Skupina proxy (2+ proxy), která provádí všechny kontroly *zvenku* a přes cloudová API: weby, certifikáty, DNS a RDAP, Graph/M365, cloudy výrobců, ping na veřejné IP WAN linek zákazníků a WebDriver pro položky prohlížeče.
- ✔ Nezbytné v jakémkoli návrhu: tyto kontroly musí přicházet zvenku sítě zákazníka.
- ✔ Skupina proxy zajišťuje HA a vyvažování zátěže. Druhý bod měření (malá proxy v jiném cloudovém regionu) umožní, aby triggery výpadku webu/WAN vyžadovaly selhání z *obou* míst, což odstraní většinu falešných poplachů.

#### E. Vstupní (ingress) skupina proxy pro agenty připojené z internetu
Proxy v DMZ Integritu přijímají aktivní agenty z hostů, kteří nemají lokalitu (cloudové VM, servery v Azure/AWS, jediný hostovaný server zákazníka), s PSK nebo certifikátem pro každého hosta.
- ✔ Server zůstává privátní a agenti přesto mají bod s bufferem.
- U malé platformy může jít o stejnou skupinu proxy jako D; rozdělit později.

### 3.2.3 Doporučený standard

**Proxy v každé lokalitě (B) jako výchozí řešení, plus centrální proxy pro externí kontroly (D) a vstupní proxy (E). VPN (C) jen jako výjimka.**

| Situace zákazníka | Konektivita |
|---|---|
| Lokalita se zařízeními v LAN a/nebo servery | Proxy v lokalitě (B) |
| Kritická lokalita (tier `critical`) | Dvě proxy v lokalitě ve skupině proxy 7.0 (agenti musí mít 7.0+) |
| Jen cloudové / hostované servery | Agenti → vstupní skupina proxy (E) |
| Jen služby web / DNS / M365 / cloudová konzole | U zákazníka nic; centrální proxy (D) |
| Pobočky bez serverů | Proxy v centrále dotazuje pobočky přes vlastní site-to-site VPN zákazníka; samostatná proxy na pobočce jen tehdy, když má vlastní lokální zařízení, která stojí za monitoring, a nespolehlivé propojení mezi lokalitami |
| Zákazník odmítá jakékoli zařízení | Proxy na straně Integritu přes existující správcovskou VPN (C) |

#### Specifikace proxy v lokalitě (standard Integritu)

Jeden standardní build proxy, nasazovaný ve dvou provedeních podle lokality. Obě provedení mají stejný OS, konfiguraci i správu, liší se jen hostitel.

| | Provedení 1: VM (výchozí) | Provedení 2: appliance Integritu |
|---|---|---|
| Kdy | Lokalita má hypervisor (většina zákazníků) | Lokalita bez virtualizace nebo zákazník nechce VM na svém hypervisoru |
| Hostitel | VM na hypervisoru zákazníka | Bezventilátorové mini-PC třídy Intel N100, 8 GB RAM, SSD 128–256 GB (typ Protectli / OnLogic), nebo levnější repasovaný Lenovo ThinkCentre Tiny / Dell OptiPlex Micro |
| Prostředky | 2 vCPU, 2–4 GB RAM, disk 20–40 GB; stačí pro typickou SMB lokalitu do několika set hostů | Viz výše; výkonová rezerva pro budoucí položky prohlížeče nebo více lokalit |
| Dodání | Golden image: OVA (VMware), VHDX (Hyper-V), šablona Proxmox; dokončení přes Ansible, nasazení zhruba za 30 minut | Předinstalováno v Integritu ze stejného image, u zákazníka jen zapojit |
| Umístění | Na hypervisoru zákazníka | Napájení z UPS, v zamčeném racku nebo místnosti; šifrování disku |
| Orientační cena | V ceně poplatku za onboarding lokality | Hardware cca 5 000–8 000 Kč (odhad, ověřit u dodavatele); prodej jednorázově, nebo měsíční pronájem |
| Nevhodné | | Raspberry Pi v produkci (opotřebení SD karet) |

- **OS a software:** Debian 12 nebo Ubuntu 24.04 LTS (případně kompatibilní s RHEL), Zabbix proxy 7.0.x z oficiálního repozitáře Zabbixu, **SQLite** jako DB proxy (pro rozsah lokality stačí).
- **Režim:** **aktivní proxy**, spojení jen odchozí na TCP 10051 ke vstupním adresám Integritu. Na firewallu zákazníka se nic příchozího neotevírá.
- **Šifrování:** jedinečný PSK pro každou proxy, nebo certifikáty.
- **Ukládání při výpadku:** hybridní buffer (paměť + disk), `ProxyOfflineBuffer` 24–72 h, aby výpadek internetu nezpůsobil ztrátu dat.
- **Doplňky instalované v každém image proxy:** `snmptrapd` + příjemce trapů Zabbixu, rsyslog (zapisuje vybraný syslog do souboru čteného lokálním agentem 2), Zabbix agent 2 (vlastní monitoring, lokální skriptové položky) a kontrolní skripty Integritu (SIP OPTIONS, RDAP, pomocné skripty pro Graph) jako `ExternalScripts`.
- **Síť:** odchozí TCP 10051 jen na vstupní adresy Integritu, plus DNS, NTP a aktualizace OS. Příchozí z LAN: SNMP trapy (UDP 162), syslog (UDP/TCP 514) a aktivní agenti (TCP 10051) z lokálních serverů. Proxy potřebuje přístup k SNMP a API zařízení: buď umístit do správcovské VLAN, nebo povolit pravidlem na firewallu. Nic příchozího z internetu.
- **Správa a bezpečnost:** vzdálená správa přes RMM/SSH Integritu po stejné odchozí cestě, automatické bezpečnostní aktualizace OS (balíčky Zabbixu vyloučeny, ty se aktualizují řízeně), žádné interaktivní účty kromě nouzového (break-glass) účtu Integritu, konfigurace přes Ansible.
- **Životní cyklus:** proxy následují hlavní verzi serveru. Upgrady se orchestrují přes Ansible: nejdřív server, pak proxy.
- **Pracnost nasazení:** 2–4 h pro první proxy u zákazníka (s připraveným image), 1 h pro každou další lokalitu. To *není* zahrnuto v údajích katalogu o nasazení na zařízení a mělo by jít o jednorázový **poplatek za onboarding lokality**.

#### Specifikace vstupních / externích proxy
- 2+ proxy ve skupině v různých doménách selhání, každá 4 vCPU / 8 GB.
- Veřejné statické IP adresy, sdělené zákazníkům, aby je mohli povolit (WAF, firewally, ochrana webů proti botům).
- Externí skupina hostuje také Selenium WebDriver (kontejner) pro položky prohlížeče.

### 3.2.4 Závislosti a logika výpadků

Návrh konektivity dává logice upozornění jasný obraz řetězce výpadku:

```
Proxy offline  ─┬─ external ping to customer WAN IP also fails → "Site ACME/Praha unreachable (WAN or power)"  [Katastrofa]
                └─ external ping OK                            → "Monitoring proxy ACME/Praha down"           [Vysoká, Integrit-internal]
Proxy online, router/firewall unreachable → "Firewall down" ; all devices behind it suppressed by trigger dependencies
```

- Každý host v lokalitě závisí na triggeru brány lokality. Každá lokalita závisí na triggeru dostupnosti proxy. Tím se předejde lavinám upozornění (jeden tiket místo 40).
- Trigger „proxy naposledy viděna“ je v každé lokalitě zákazníka nejdůležitějším triggerem, protože jinak lokalita ztichne, aniž by si toho kdokoli všiml.

### 3.2.5 Potřebná rozhodnutí
1. Přijmout standard **proxy v lokalitě jako výchozí řešení** a jednorázový poplatek za onboarding lokality.
2. Kde budou centrální a externí proxy (na stejném místě jako server, nebo ve druhé lokalitě pro pohled zvenčí).
3. Hardwarový standard pro lokality bez virtualizace: navrženo mini-PC třídy Intel N100 (kapitola 3.2.3). Zbývá rozhodnout, zda se bude prodávat, pronajímat, nebo bude v ceně.
4. Zda využít stávající správcovské VPN Integritu (jen jako výjimka).


## 3.3 Alerting dnes a cesta k Microsoft Planneru

### 3.3.1 Současný stav
Všechna upozornění odcházejí e-mailem přes Microsoft Graph na **monitoring@integrit.cz**. Ve verzi 7.0.31 to musí být **typ média webhook** (JavaScript volající Graph `sendMail`), protože nativní OAuth pro e-mailový typ média existuje až od 7.4.

#### Zpevnění e-mailového typu média přes Graph

| Oblast | Doporučení |
|---|---|
| Autentizace | Registrace aplikace v Entra, tok client credentials, **certifikát** má přednost před client secretem (expirace secretu je klasický tichý výpadek). Expiraci secretu/certifikátu sledovat přímo v Zabbixu. |
| Oprávnění | *Aplikační* oprávnění `Mail.Send` umožňuje aplikaci odesílat jménem **libovolné** schránky v tenantu. Omezit ho na odesílací schránku přiřazením Exchange **RBAC for Applications** (nebo starší Application Access Policy). |
| Odesílatel | Vyhrazená schránka, např. `zabbix@integrit.cz`, odesílající na `monitoring@integrit.cz`. Udržuje pravidla doručené pošty a audit přehledné. |
| Viditelnost selhání | Trigger na neúspěšná upozornění (interní položka `zabbix[alerts…]` / chyby typu média) plus externí dead-man switch (kapitola 3.1.6). |
| Formát předmětu | `[ACME][HIGH][MON-SRV] ACME-PRG-SRV-DC01: Disk C: is 95% full` – pravidla schránky, vyhledávání i pozdější parsování jsou pak triviální. |
| Tělo | Problém, závažnost, čas začátku, host, lokalita, služba, aktuální hodnota, odkaz na událost, ID události a tagy. Zprávy o zotavení a aktualizaci používají stejný předmět plus `RESOLVED` / `UPDATE`, takže se seskupí do vláken. |

#### Akce (pravidla směrování upozornění)
Navrhnout je hned s tagy z kapitoly 3.1, aby přechod na Planner a kontakty zákazníků byl jen otázkou přidání akcí:

| # | Podmínka | Operace (dnes) | Později |
|---|---|---|---|
| A1 | závažnost ≥ Varování, všichni zákazníci | e-mail na monitoring@ | zůstává jako auditní kopie / pohled NOC |
| A2 | `managed = no`, závažnost ≥ Průměrná | – | e-mail na kontakt zákazníka (uživatel Zabbixu pro každého zákazníka s médiem, omezený tagem `customer`) |
| A3 | `managed = yes`, závažnost ≥ Průměrná, stále otevřeno po 10 min (Vysoká/Katastrofa: okamžitě) | – | založit úkol v Planneru |
| A4 | závažnost = Katastrofa, `tier = critical`, mimo pracovní dobu | – | SMS/telefonát technikovi ve službě |
| A5 | Interní: výpadek proxy, selhání média, chyby šablon | e-mail na monitoring@ | plán platformy Integritu v Planneru |

#### Omezení šumu (musí být zavedeno před automatizací tiketů)
- **Závislosti triggerů** pro každou lokalitu (kapitola 3.2.4).
- **Hystereze** (oddělené výrazy pro problém a zotavení) a `min()`/`avg()` přes časová okna místo jednotlivých hodnot.
- **Zpoždění před vytvořením tiketu:** krok eskalace 1 až po 10 minutách u Průměrná, aby kolísání (flapping) nevytvářelo tikety.
- **Období údržby** pro každého zákazníka (okna pro záplatování) a během nich *potlačení* problémů.
- **Týdenní revize „nejhlučnějších triggerů“** během pilotu (nativní report *Top 100 triggers*).
- **Korelace událostí** (globální korelační pravidla) pro známé dvojice, např. „link down“ plus „link up“ na stejném rozhraní.

### 3.3.2 Cíl: tikety v Microsoft Planneru

#### Co Graph podporuje
- Úkoly v Planneru lze vytvářet, číst, aktualizovat a mazat **v režimu aplikace (app-only)** s *aplikačním* oprávněním `Tasks.ReadWrite.All` (`POST /planner/tasks`, `PATCH /planner/tasks/{id}`, `PATCH /planner/tasks/{id}/details`) ([přehled oprávnění](https://graphpermissions.merill.net/permission/Tasks.ReadWrite.All.html)).
- PATCH vyžaduje aktuální `@odata.etag` úkolu v hlavičce `If-Match`, takže každá aktualizace potřebuje nejdřív GET.

#### Limity Planneru, které ovlivňují návrh ([Microsoft Learn](https://learn.microsoft.com/en-us/planner/planner-limits))

| Limit | Hodnota | Dopad |
|---|---|---|
| Úkoly v plánu | celkem 9 000 | Integrit má jeden společný plán, takže limit sdílejí všichni zákazníci i ruční tikety. Monitoring generuje mnoho úkolů, proto je nutná pravidelná archivace dokončených úkolů (viz níže) |
| Aktivní (nedokončené) úkoly v plánu | 3 000 | Automaticky vyřešené úkoly je nutné dokončovat |
| Buckety v plánu | 200 | Bucket na zákazníka (stávající konvence Integritu) stačí do 200 zákazníků včetně případných interních bucketů; při přiblížení k limitu rozdělit plán (např. podle abecedy nebo podle týmu) |
| Řešitelé úkolu | 20 | V pořádku |
| Položky kontrolního seznamu | 20 | V pořádku (použít pro „kroky runbooku“) |

#### Nedostatky Planneru jako tiketovacího systému (přijmout, nebo kompenzovat)
- Žádné SLA časovače, měření doby reakce/vyřešení ani časová eskalace. Musí je počítat eskalace v Zabbixu a vlastní report.
- Přes Graph není u úkolu k dispozici konverzační vlákno (komentáře nejsou přes API dostupné), takže informace o zotavení se zapisují do popisu úkolu.
- Jen 4 úrovně priority a nejvýše 25 štítků. Závažnost mapovat na prioritu a štítky použít pro ID služeb.
- Žádná deduplikace; ta se musí řešit na straně Zabbixu (jeden úkol na jednu událost problému).
- Žádný zákaznický portál ani příjem e-mailem.

#### Mapování

| Zabbix | Planner |
|---|---|
| Tag `customer` | Bucket daného zákazníka ve společném plánu. Mapování kód zákazníka → ID bucketu je v evidenci zákazníků (3.1.5); webhook ho čte z makra nebo parametru, mezivrstva z vlastní tabulky. Chybějící bucket = úkol do bucketu „Nezařazeno – monitoring“ a upozornění pro správce |
| Závažnost Katastrofa/Vysoká/Průměrná/Varování | Priorita Urgentní/Důležitá/Střední/Nízká |
| Tag `service` | Štítek (např. „MON-BKP“) |
| Název problému + host | Název úkolu `[ACME] DC01: Disk C: 95% full` |
| Podrobnosti, odkaz na událost, odkaz na runbook | Popis úkolu (details) |
| ID události | Uloženo v popisu; ID úkolu v Planneru se zapíše zpět k události v Zabbixu jako tag `planner_task` |
| Zotavení | Popis doplněn o čas zotavení; úkol buď dokončen, nebo označen štítkem „Zotaveno – ověřit“ (rozhodnutí níže). Úkol zůstává v bucketu zákazníka, protože buckety jsou vyhrazeny zákazníkům |
| Potvrzení (acknowledge) v Zabbixu | Volitelně: přiřadit technikovi, který problém potvrdil |

#### Varianty implementace

| | 1. Webhook Zabbixu → přímo Graph | 2. Tok Power Automate | 3. Mezivrstva (Azure Function / Logic App) |
|---|---|---|---|
| Jak | Typ média v JavaScriptu: získá token, vytvoří úkol, vrátí ID úkolu jako tag události („process tags“); druhá operace při zotavení úkol aktualizuje | Zabbix posílá data na HTTP trigger toku; tok vytváří/aktualizuje úkoly konektorem Planner | Zabbix posílá událost na HTTPS endpoint; funkce udržuje mapovací tabulku (zákazník→bucket, událost→úkol), řadí do fronty, opakuje pokusy a zapisuje do Planneru |
| Pracnost | 16–24 h | 16–32 h | 40–80 h |
| Robustnost | Střední. Opakování je omezeno na opakování médií v Zabbixu; throttling Graphu (429) je nutné ošetřit v JS | Středně nízká. HTTP trigger vyžaduje prémiovou licenci; selhání toků jsou hůře viditelná | Vysoká. Fronta, opakování, idempotence, auditní log, jedno místo pro obchodní pravidla |
| Flexibilita změn | Každá změna mapování je úpravou typu média v Zabbixu | Low-code, snadné i pro nevývojáře | Kód, ale verzovaný a testovatelný |
| Závislost na dodavateli | Žádná | Licencování Power Platform | Malé náklady na Azure |

**Doporučení:** v pilotu začít **variantou 1**. Nevyžaduje žádnou novou infrastrukturu a ověří mapování. Na **variantu 3** přejít, jakmile bude v provozu více než ~10 spravovaných zákazníků, nebo pokud se pravidla pro Planner zkomplikují. Integrit si může ponechat stejné akce v Zabbixu a vyměnit jen typ média.

#### Potřebná rozhodnutí k Planneru
1. ~~Jak je dnes Planner strukturován~~ **Rozhodnuto 15. 10. 2026:** jeden společný plán, každý zákazník má vlastní bucket. Integrace monitoringu tuto konvenci přebírá. Důsledky: bucket se vybírá podle tagu `customer`, stav k ověření se značí štítkem místo bucketu, limit 9 000 úkolů platí pro všechny zákazníky dohromady a limit 200 bucketů omezuje počet zákazníků v jednom plánu.
2. Při zotavení: úkol automaticky dokončit, nebo ho označit štítkem „Zotaveno – ověřit“, aby ho uzavřel člověk? Doporučení: automaticky dokončit u Varování/Průměrná, štítek k ověření u Vysoká/Katastrofa.
3. Které závažnosti vytvářejí úkoly. Doporučení: Průměrná a vyšší pro `managed = yes`.
4. Zda je zákazník informován z Planneru (ručně), nebo také e-mailem ze Zabbixu (automaticky).
5. Vlastník rotace plánu (archivace nebo mazání dokončených monitoringových úkolů starších než N měsíců), aby se nepřekročil limit 9 000 úkolů. U společného plánu je to podmínka provozu, ne volba: doporučení je měsíční automatický export dokončených monitoringových úkolů (do SharePoint seznamu kvůli historii a reportům) a jejich smazání z plánu.

**Dlouhodobě:** pokud se absence sledování SLA a komunikace se zákazníkem v Planneru stane problémem, Zabbix má hotové webhooky pro specializované service desky (Jira Service Management, Zammad, Freshservice, ServiceNow, TOPdesk a další). Tento návrh udržuje takový přechod levný, protože směrování je řízeno tagy.


## 3.4 Měsíční reporting pro zákazníky

Každá služba katalogu slibuje reporting (dostupnost, incidenty, kapacitní trendy, poslední úspěšná záloha, využití licencí…). Dnes neexistuje žádný nástroj pro reporting.

### 3.4.1 Co musí reporty obsahovat (podle katalogu)

| Služba | Slíbený obsah reportu |
|---|---|
| MON-SRV | Měsíční dostupnost, incidenty, kapacitní trendy, doporučení |
| MON-VIRT | Dostupnost, kapacita, alarmy, rizika sdílených prostředků |
| MON-NAS | Kapacita, zdraví disků, RAID, incidenty |
| MON-BKP | Míra úspěšnosti, neúspěšné a chybějící běhy, poslední úspěšná záloha |
| SRV-RESTORE | Protokol testu: rozsah, výsledek, zjištění |
| MON-NET | Dostupnost, výpadky, latence, failovery, stabilita VPN |
| MON-LAN | Dostupnost, incidenty na portech, chybovost, uplinky, PoE |
| MON-UPS | Výpadky napájení, baterie, zátěž, doba výdrže, testy |
| MON-WEB | Dostupnost, doba odezvy, výpadky |
| MON-DNS | Blížící se expirace, změny kritických záznamů |
| MON-WP | Souhrnný stav webů, aktualizace, problémy |
| MON-WEB-FUNC | Dostupnost scénářů, incidenty, doba odezvy |
| MON-EPS | Aktivní/neaktivní zařízení, závažné události |
| MON-M365 | Licence, nevyužitá kapacita, změny, obnovy předplatného |
| MON-VOIP | Dostupnost, výpadky registrací, významné události |
| MON-CUSTOM | Pro každou kontrolu: míra úspěšnosti, incidenty |

Společné požadavky: **jeden souhrnný report na zákazníka** s oddílem pro každou předplacenou službu. Čeština, branding Integritu, PDF, krátká lidsky psaná část „doporučení“ a automatické měsíční doručení. K tomu archiv.

### 3.4.2 Varianty

#### Varianta 1: Nativní Zabbix (SLA modul, report dostupnosti, plánované reporty)
- **SLA modul** (strom služeb + SLA objekty): dostupnost pro zákazníka/službu s SLO, vyloučenými odstávkami (údržba) a měsíčními SLA reporty ve frontendu.
- **Plánované reporty:** podle plánu posílají e-mailem PDF dashboardu. Vyžadují Zabbix web service s headless Chrome. Šablonové dashboardy pro každou službu.
- ✔ Zdarma, nic dalšího k provozu, lze začít okamžitě.
- ✘ PDF je snímek dashboardu: žádný komentář, slabá kontrola nad rozvržením, jeden dashboard na report, nešikovný vícestránkový výstup.
- ✘ Plánované reporty se posílají uživatelům Zabbixu, takže každý příjemce u zákazníka se stává uživatelem Zabbixu.
- ✘ Žádný souhrnný dokument „všechny služby“, pokud se pro každého zákazníka nepostaví jeden velký dashboard.
- **Vhodnost:** interní pohledy a dočasné řešení na začátku. Ne měsíční report v kvalitě pro zákazníka.

#### Varianta 2: Grafana + plugin datového zdroje Zabbix
- Zákaznicky šablonované dashboardy (proměnná zákazníka) nad daty Zabbixu přes plugin Zabbix.
- ✔ Mnohem lepší vizualizace; vhodné pro interní NOC stěnu a volitelné zákaznické portály (jedna organizace Grafany na zákazníka).
- ✘ PDF reporting a plánované doručování jsou funkce **Grafana Enterprise / Cloud**. S OSS je potřeba image renderer a vlastní sestavování PDF.
- ✘ Druhý systém, který je třeba zabezpečit, aktualizovat a udržovat jako multi-tenant.
- **Vhodnost:** dashboardy a portály, ne měsíční PDF, pokud se nekoupí Enterprise.

#### Varianta 3: Vlastní generátor reportů nad API Zabbixu (doporučeno)
Malá služba spouštěná jednou měsíčně plánovačem:
1. Pro každého zákazníka v evidenci načte předplacené služby (tagy).
2. Přes API Zabbixu stáhne: výsledky SLA (`sla.getsli`), problémy a události s dobou trvání, trendy kapacitních metrik, výsledky zálohovacích úloh, počty licencí atd.
3. Vykreslí HTML šablonu pro každý oddíl služby (Jinja2) s brandingem Integritu a českým textem. Převede ji do PDF (WeasyPrint nebo headless Chromium).
4. Ponechá pole „doporučení“, které může technik vyplnit před vydáním (koncept → revize → odeslání), nebo automaticky vygeneruje standardní doporučení podle pravidel (např. „disk D: bude plný přibližně za 45 dní“).
5. Doručí report e-mailem přes Graph kontaktům zákazníka a archivuje ho do SharePointu. Ze stejných dat vytvoří fakturační export.
- ✔ Přesně odpovídá slibům katalogu pro jednotlivé služby i brandingu; jeden souhrnný report na zákazníka.
- ✔ Zákazníci nepotřebují účty v Zabbixu.
- ✔ Stejná data slouží fakturaci i interní revizi.
- ✘ Vývoj: **80–140 h** na framework a oddíly pilotních služeb, pak **4–12 h na každý další oddíl služby**. K tomu údržba.

#### Varianta 4: Power BI
Noční extrakce z API Zabbixu do datové sady (Azure SQL / Fabric), reporty Power BI se zabezpečením na úrovni řádků (RLS) pro každého zákazníka a export do PDF přes stránkované reporty.
- ✔ Interaktivní, sedí do firmy orientované na Microsoft a vhodné pro interní manažerské KPI (šum, MTTR, pokrytí).
- ✘ Licencování: odběry PDF stránkovaných reportů vyžadují kapacitu Premium/Fabric nebo licence na uživatele. Přístup zákazníků vyžaduje licence nebo embedding.
- ✘ Nejvíce pohyblivých částí (ETL, datová sada, RLS, kapacita).
- **Vhodnost:** později pro interní manažerskou analytiku, ne pro první zákaznický report.

#### Varianta 5: Komerční reportingové doplňky pro Zabbix
Existují produkty třetích stran, které generují PDF reporty ze Zabbixu. Pokud Integrit dává přednost nákupu před vývojem, stojí za krátké vyhodnocení. Ověřit kompatibilitu se 7.0, multi-tenancy a šablonování v češtině.

### 3.4.3 Srovnání

| Kritérium | 1 Nativní | 2 Grafana | 3 Vlastní generátor | 4 Power BI |
|---|---|---|---|---|
| Odpovídá obsahu katalogu pro jednotlivé služby | ◐ | ◐ | ● | ● |
| Souhrnný report na zákazníka | ○ | ◐ | ● | ● |
| Branding / čeština / komentář | ○ | ◐ | ● | ● |
| Zákazník potřebuje účet | ano | ano (nebo PDF přes Enterprise) | ne | ano, nebo PDF přes Premium |
| Další licence | žádné | Enterprise pro PDF | žádné | Premium/Fabric nebo PPU |
| Pracnost vývoje | 16–32 h | 40–60 h | 80–140 h | 100–160 h |
| Pracnost provozu | nízká | střední | nízká–střední | střední–vysoká |

### 3.4.4 Doporučení
1. **Hned:** nastavit **SLA modul** (služby pro kombinace zákazník × služba katalogu), jakmile budou hosté zavedeni. Výsledky SLA se počítají z historie stavu služeb, takže služby, které ještě neexistují, nelze reportovat zpětně. Interně používat nativní dashboardy.
2. **Pilot:** postavit **vlastní generátor (varianta 3)** nejprve pro pilotní služby (MON-WEB, MON-DNS, MON-SRV, MON-BKP, MON-UPS) a první skutečný report odeslat po jednom celém měsíci dat.
3. **Později, volitelně:** Grafana pro interní NOC stěnu nebo zákaznický portál a Power BI pro interní manažerské KPI.

#### Potřebná rozhodnutí k reportům
1. Jeden souhrnný report na zákazníka (doporučeno), nebo na službu. Šlo o bod k rozhodnutí z v1.0, který ve v1.1 vypadl.
2. Revize technikem před odesláním (zvyšuje kvalitu, stojí ~15–30 min na zákazníka), nebo plně automaticky.
3. Zda report ve výchozím stavu obsahuje oddíl „Doporučení Integritu“, nebo jen u spravovaných zákazníků.
4. Doručení: jen PDF e-mailem, nebo také archiv v SharePointu/portálu, ke kterému má zákazník přístup.

# Část 4 · Služby katalogu

Každá služba má tři oddíly:

- **Zákaznický pohled:** položka katalogu tak, jak ji čte zákazník (z v1.1, s doplněnými podrobnostmi z v1.0).
- **Obchodní pohled:** cílový zákazník, jednotka, orientační cena a pracnost uvedená přímo v katalogu.
- **Technický návrh:** návrh pro Zabbix 7.0.31, vždy ve stejných deseti bodech:
  1. Rozsah: co se monitoruje
  2. Zdroje dat a mechanismus Zabbixu (oficiální šablony vs. vlastní řešení Integritu)
  3. Místo sběru: proxy v lokalitě, externí proxy nebo vstupní (ingress) proxy (kapitola 3.2)
  4. Předpoklady na straně zákazníka: kontrolní seznam pro onboarding
  5. Výchozí triggery a prahy: závažnost a výchozí hodnota, kterou lze pro každého zákazníka přepsat
  6. Závislosti a ochrana proti falešným poplachům
  7. Obsah reportu
  8. Varianty výrobců nebo platforem pro první vydání
  9. Pracnost: produktizace (jednorázově) a nasazení (na zákazníka), ve srovnání s katalogem
  10. Rizika a otevřené body

Tagy, závažnosti a pojmenování se řídí kapitolou 3.1, konektivita kapitolou 3.2. Dostupnost šablon byla ověřena proti oficiální větvi Zabbixu `release/7.0`.


## 4.1 MON-SRV · Monitoring serveru

### Zákaznický pohled (položka katalogu)

| Pole | Obsah |
|---|---|
| ID | `MON-SRV` |
| Český název | Monitoring serveru |
| Co monitorujeme | Dostupnost serveru, CPU, RAM, disky, služby, procesy, plánované úlohy, systémové chyby, aktualizace OS a odezvu sítě. |
| Přínos | Včasné odhalení výpadku, docházející kapacity nebo zastavené služby; automatická kontrola bez čekání, až problém nahlásí uživatelé. |
| Riziko | 🟠 Vysoké. Výpadek může zastavit aplikace, přístup k souborům a práci uživatelů. |
| Předpoklady na straně zákazníka | Známá role serveru a kritické služby; možnost sběru dat (agent); zabezpečená komunikační cesta. |
| Reporting | Měsíční dostupnost, incidenty, trendy kapacity a doporučení. |
| Omezení | Bez samostatných aplikačních kontrol neověřuje správnost dat ani uživatelské procesy. |
| Hranice služby | Monitoring zahrnuje sběr dat, vyhodnocení a upozornění. Odstranění problému, správa, aktualizace a incident response nejsou součástí, pokud nejsou sjednány zvlášť. |

### Obchodní pohled

| Pole | Obsah |
|---|---|
| Cílový zákazník | Provozovatelé fyzických, virtuálních nebo cloudových serverů. |
| Obchodní potenciál | Vysoký (odhad, ověřit na portfoliu zákazníků) |
| Jednotka | server / měsíc |
| Orientační cena | 300–600 Kč (odhad) |
| Produktizace (katalog) | 12–24 h |
| Nasazení (katalog) | 0,5–2 h na server; sdílená konektivita zvlášť |
| Navazující služby | Správa serverů, patchování, monitoring aplikací, plánování kapacit. |
| Doručení upozornění | Bez správy: určený kontakt zákazníka. Se správou Integrit: servisní proces Integritu (úkol v Planneru). |

**Poznámka z analýzy:** v1.1 bez vysvětlení vypustila z rozsahu „aktualizace“. Tento návrh je ponechává.

### Technický návrh

**1. Rozsah**
Dostupnost (heartbeat agenta plus ICMP), CPU, RAM, swap/pagefile, souborové systémy (místo a inody), latence diskových I/O, síťová rozhraní, služby Windows / jednotky systemd, kritické procesy, plánované úlohy (Plánovač úloh Windows, cron), chyby v systémových událostech (Event Log / journal), čekající aktualizace OS a příznak nutného restartu, synchronizace času (NTP), uptime / neočekávané restarty a SMART na fyzických serverech.

**2. Mechanismus ve verzi 7.0.31**

| Oblast | Jak | Oficiální? |
|---|---|---|
| Základy OS | *Windows by Zabbix agent active*, *Linux by Zabbix agent active* | Ano |
| Služby | Windows: LLD služeb ze šablony, filtrované na typ spuštění „automatic“ + seznam zahrnutých služeb Integritu podle role. Linux: *systemd by Zabbix agent 2* | Ano, vyžaduje doladění filtrů |
| Event log / journal | Aktivní položky `eventlog[]` / `log[]` se sadami regulárních výrazů Integritu podle role (např. chyby disků, NTFS, VSS, clusteru, replikace AD) | Vlastní řešení Integritu |
| Plánované úlohy | Windows: PowerShell UserParameter s LLD (`Get-ScheduledTask` + `Get-ScheduledTaskInfo`: poslední výsledek, poslední a příští spuštění), zahrnuje jen úlohy ve složce Integritu nebo označené názvem. Linux cron: obálka (`int-cron-wrap`), která posílá návratový kód a dobu běhu přes `zabbix_sender`, plus `nodata()` | Vlastní řešení Integritu |
| Aktualizace | Windows: PowerShell (Windows Update API, počet čekajících bezpečnostních/kritických aktualizací, dny od poslední instalace, čekající restart). Linux: kontrolní skript pro apt/dnf. Spouštět každých 6–12 h | Vlastní řešení Integritu |
| NTP | Trigger na časový posun ze šablony, plus posun z Windows `w32tm` nebo Linux `chronyc` přes UserParameter | Částečně oficiální |
| SMART | *SMART by Zabbix agent 2* (vyžaduje smartctl), jen fyzické servery. Hardwarové RAID řadiče vyžadují nástroje výrobce nebo spadají pod MON-HW (kapitola 5.6.1) | Ano |
| Agent | **Zabbix agent 2, 7.0.x**, pouze aktivní režim, TLS PSK, `system.run` zakázán s výjimkou skriptů Integritu přes `AllowKey` | – |

**3. Místo sběru:** aktivní agent → proxy v lokalitě; cloudové servery → skupina vstupních (ingress) proxy.

**4. Předpoklady na straně zákazníka:** administrátorská práva pro instalaci agenta (nebo balíček GPO/Intune od Integritu); role serveru a seznam jeho kritických služeb a plánovaných úloh; okno pro patchování a údržbu; kontaktní osoba.

**5. Výchozí triggery**

| Trigger | Závažnost | Výchozí hodnota |
|---|---|---|
| Server nedostupný (agent nodata 3 min A ZÁROVEŇ selhání ICMP) | Vysoká (Katastrofa pro `tier=critical`) | `{$AGENT.NODATA.TIMEOUT}=3m` |
| Místo na souborovém systému | Varování / Vysoká | 85 % / 95 %, nebo < 10 GB volného místa na velkých svazcích; predikce „zaplnění za < 14 dní“ (timeleft) Průměrná |
| Zátěž CPU | Varování | > 90 % průměr za 15 min |
| Dostupná paměť | Průměrná | < 10 % po dobu 10 min |
| Zastavená kritická služba | Vysoká | Seznam Integritu podle role |
| Plánovaná úloha selhala / neproběhla | Průměrná | poslední výsledek ≠ 0, nebo poslední spuštění starší než `{$TASK.MAX.AGE:"name"}` |
| Čekající bezpečnostní aktualizace | Varování | > 0 bezpečnostních aktualizací starších než 14 dní; čekající restart > 7 dní |
| Časový posun | Průměrná | > 60 s |
| Neočekávaný restart | Informace (report) / Varování | uptime < 10 min mimo okno údržby |
| Opakovaná chyba v event logu | Průměrná | shoda se sadou regulárních výrazů, ≥ N za 15 min |
| Selhání SMART | Vysoká | stav SMART ≠ OK, rostoucí počet realokovaných sektorů |

**6. Závislosti / falešné poplachy:** závisí na dostupnosti brány lokality a proxy. Okna pro patchování jako údržba (maintenance) v Zabbixu. Regulární výrazy pro event log začínají konzervativně a ladí se během pilotu.

**7. Report:** dostupnost jednotlivých serverů (SLA), incidenty s dobou trvání, trendy kapacity (růst disků a predikce, CPU/RAM p95), souhrn stavu patchování, doporučení.

**8. Platformy pro první vydání:** Windows Server 2016–2025 i aktuální linuxové distribuce (rodina Debian/Ubuntu/RHEL) pokrývají stejné oficiální šablony, takže lze spustit obojí současně.

**9. Pracnost:** produktizace **24–40 h** (katalog: 12–24 h). Rozdíl tvoří komponenty pro plánované úlohy, aktualizace a event log, které jsou vlastní. Nasazení: **0,5–1 h na server** s instalátorem, 1–2 h na doladění podle role.

**10. Rizika / otevřené body:** „aktualizace“ byly ve v1.1 z rozsahu vypuštěny, ale ve v1.0 jsou; doporučujeme je ponechat, protože jsou levné a zákazníci je oceňují. Agent na řadičích domény vyžaduje u některých zákazníků bezpečnostní posouzení.


## 4.2 MON-VIRT · Monitoring virtualizační platformy

### Zákaznický pohled (položka katalogu)

| Pole | Obsah |
|---|---|
| ID | `MON-VIRT` |
| Český název | Monitoring virtualizační platformy |
| Co monitorujeme | Hypervizory, clustery, virtuální stroje, úložiště, kapacitu a alarmy platformy. |
| Přínos | Jeden pohled na virtualizační vrstvu; odhalí problémy, které zasáhnou více serverů najednou; plánování kapacit. |
| Riziko | 🔴 Kritické. Selhání hostitele nebo sdíleného úložiště může zasáhnout mnoho systémů najednou. |
| Předpoklady na straně zákazníka | Podporované rozhraní platformy, účet jen pro čtení a známý rozsah prostředí. |
| Reporting | Dostupnost, kapacita, alarmy a rizika sdílených prostředků. |
| Omezení | Nenahrazuje monitoring OS a aplikací uvnitř virtuálních strojů. |
| Hranice služby | Monitoring zahrnuje sběr dat, vyhodnocení a upozornění. Odstranění problému, správa, aktualizace a incident response nejsou součástí, pokud nejsou sjednány zvlášť. |

### Obchodní pohled

| Pole | Obsah |
|---|---|
| Cílový zákazník | VMware, Hyper-V nebo jiná virtualizace (stále častěji Proxmox). |
| Obchodní potenciál | Střední až vysoký (odhad, ověřit na portfoliu zákazníků) |
| Jednotka | host nebo platforma / měsíc |
| Orientační cena | 500–1 200 Kč za host (odhad) |
| Produktizace (katalog) | 8–20 h na platformu |
| Nasazení (katalog) | 1–3 h na prostředí |
| Navazující služby | Správa platformy, plánování kapacit, MON-SRV uvnitř virtuálních strojů. |
| Doručení upozornění | Bez správy: určený kontakt zákazníka. Se správou Integrit: servisní proces Integritu (úkol v Planneru). |

### Technický návrh

**1. Rozsah:** hostitelé hypervizoru (stav, CPU, RAM, overcommit), zdraví clusteru (HA/DRS, quorum), datastory/úložiště (kapacita, latence), virtuální stroje (stav napájení, snapshoty starší než N dní, VMware Tools / guest agent), hardwarové senzory hostitelů, alarmy platformy, závislosti VM na hostiteli.

**2. Mechanismus ve verzi 7.0.31**

| Platforma | Jak | Oficiální? |
|---|---|---|
| VMware vSphere (vCenter nebo samostatný ESXi) | Nativní VMware collector (`StartVMwareCollectors` na proxy v lokalitě); šablony *VMware*, *VMware Hypervisor*, *VMware Guest* s discovery hostitelů a VM; role vCenter jen pro čtení | Ano, vyzrálé |
| Microsoft Hyper-V (samostatný i failover cluster) | Oficiální šablona neexistuje. Agent 2 na každém hostiteli: výkonnostní čítače Hyper-V plus PowerShell UserParametery (`Get-VM`, `Get-ClusterNode`, `Get-ClusterSharedVolume`, stav replikace, stáří checkpointů) | Vlastní řešení Integritu (nebo úprava komunitní šablony) |
| Proxmox VE | *Proxmox VE by HTTP* (API token), součást sady šablon 7.0 | Ano |
| Ostatní (XCP-ng, Nutanix) | Pouze na vyžádání | – |

**Důležité rozhodnutí v návrhu:** discovery VMware umí vytvořit hosta Zabbixu **pro každý virtuální stroj**. Doporučení: ve výchozím stavu zjišťovat VM jen jako položky (stav, snapshoty, využití prostředků). Hosty pro VM vytvářet jen tam, kde zákazník kupuje i MON-SRV, aby počty hostů a fakturace zůstaly předvídatelné. Zjištění hosté musí přes nastavení prototypů hostů zdědit skupinu zákazníka a tagy.

**3. Místo sběru:** proxy v lokalitě (API vCenter/Proxmox, agenti Hyper-V).

**4. Předpoklady na straně zákazníka:** API účet jen pro čtení (role ve vCenter nebo token Proxmox s vyjmenovanými cestami), seznam clusterů/hostitelů v rozsahu, politika snapshotů.

**5. Výchozí triggery:** hostitel odpojen / neodpovídá (Vysoká); hostitel nečekaně v režimu údržby (Varování); degradované HA/quorum clusteru (Katastrofa); volné místo na datastoru < 15 % / < 5 % (Průměrná / Vysoká); latence datastoru > 30 ms po 15 min (Průměrná); snapshot starší než 7 dní (Varování); VM v rozsahu nečekaně vypnut (Vysoká); trvalý overcommit paměti / ballooning (Varování); alarm hardwarového senzoru (Vysoká); alarm platformy (mapovaný podle jeho závažnosti).

**6. Závislosti:** VM závisejí na hostiteli, hostitelé na clusteru/úložišti a lokalitě. Pokud uvnitř VM běží MON-SRV, jeho triggery „nedostupný“ závisejí na triggeru stavu napájení VM.

**7. Report:** dostupnost hostitelů/clusterů, kapacitní rezerva (CPU/RAM/úložiště) s predikcí, hygiena snapshotů, alarmy.

**8. Varianty pro první vydání:** VMware (nejnižší pracnost, vyzrálé) a Hyper-V (u českých zákazníků z řad SMB pravděpodobně časté, ale jde o vlastní vývoj). Proxmox je třetím kandidátem, protože změny licencování VMware k němu zákazníky tlačí.

**9. Pracnost:** VMware **8–16 h**, Proxmox **8–16 h**, Hyper-V **24–40 h** (katalog: 8–20 h na platformu; sedí kromě Hyper-V). Nasazení **1–3 h na prostředí** (odpovídá katalogu).

**10. Rizika:** zátěž API vCenter u velkých prostředí (doladit intervaly); kontroly clusteru Hyper-V musí běžet jen na jednom uzlu (použít název clusteru jako hosta, nebo zvolit vlastnický uzel).


## 4.3 MON-NAS · Monitoring NAS a datového úložiště

### Zákaznický pohled (položka katalogu)

| Pole | Obsah |
|---|---|
| ID | `MON-NAS` |
| Český název | Monitoring NAS a datového úložiště |
| Co monitorujeme | Dostupnost, kapacitu, disky, RAID, teploty, napájecí zdroje, ventilátory a rozhraní. |
| Přínos | Varování před selhávajícím diskem, degradovaným polem, nedostatkem místa nebo hardwarovou závadou. |
| Riziko | 🔴 Kritické. Selhání úložiště může znamenat nedostupnost nebo ztrátu dat. |
| Předpoklady na straně zákazníka | Přístup přes SNMP nebo API, známá konfigurace disků a svazků, zabezpečená komunikační cesta. |
| Reporting | Kapacita, zdraví disků, stav RAID a incidenty. |
| Omezení | Zdravý RAID a zdravé disky nenahrazují zálohy. |
| Hranice služby | Monitoring zahrnuje sběr dat, vyhodnocení a upozornění. Odstranění problému, správa, aktualizace a incident response nejsou součástí, pokud nejsou sjednány zvlášť. |

### Obchodní pohled

| Pole | Obsah |
|---|---|
| Cílový zákazník | NAS, SAN a lokální disková pole. |
| Obchodní potenciál | Vysoký u on-premises infrastruktury (odhad, ověřit na portfoliu zákazníků) |
| Jednotka | zařízení / měsíc |
| Orientační cena | 300–700 Kč (odhad) |
| Produktizace (katalog) | 8–24 h na produktovou řadu |
| Nasazení (katalog) | 1–3 h na zařízení |
| Navazující služby | Správa úložišť, zálohování (MON-BKP), plánování kapacit. |
| Doručení upozornění | Bez správy: určený kontakt zákazníka. Se správou Integrit: servisní proces Integritu (úkol v Planneru). |

### Technický návrh

**1. Rozsah:** dostupnost, kapacita a růst svazků/poolů, zdraví disků (SMART, stav, teplota), stav RAID/poolu (degradovaný, probíhající rebuild), napájecí zdroje, ventilátory, teploty, rozhraní, upozornění na firmware/aktualizace, úlohy snapshotů/replikace tam, kde je zařízení provádí (např. Synology Snapshot Replication).

**2. Mechanismus ve verzi 7.0.31**

| Platforma | Jak | Oficiální? |
|---|---|---|
| Synology DSM | SNMPv3 (Synology MIB: systém, disky, RAID, svazky, teploty) | V sadě 7.0 oficiální šablona není; komunitní šablony → verze Integritu |
| QNAP | SNMPv3 (QNAP MIB) | Komunitní → verze Integritu |
| TrueNAS | Oficiální *TrueNAS by SNMP* | Ano |
| Enterprise SAN | Oficiální šablony 7.0 pro HPE MSA 2040/2060, HPE Primera, NetApp AFF A700 / FAS3220, Huawei OceanStor 5300 V5 / Dorado, Pure Storage FlashArray | Ano, pro tyto modely |
| Obecný NAS na bázi Linuxu | *Linux by SNMP* / HOST-RESOURCES-MIB | Ano, omezená hloubka |

**3. Místo sběru:** proxy v lokalitě (dotazování SNMP plus trapy z NAS na proxy pro okamžité upozornění na selhání disku).

**4. Předpoklady na straně zákazníka:** zapnuté SNMPv3 (Integrit to může zajistit s administrátorským přístupem), seznam svazků a jejich účel, kontakt na správce zařízení.

**5. Výchozí triggery:** zařízení nedostupné (Vysoká); RAID/pool degradovaný (Katastrofa); probíhá rebuild (Varování); disk selhal / kritický stav (Vysoká); varování SMART disku (Průměrná); svazek > 85 % / > 95 % (Průměrná / Vysoká) a predikce zaplnění < 14 dní; vysoká teplota (Průměrná); selhání zdroje/ventilátoru (Vysoká); dostupná kritická aktualizace firmwaru (Varování).

**7. Report:** kapacita a růst jednotlivých svazků, zdraví disků, události RAID, incidenty.

**8. Varianty pro první vydání:** nejprve Synology (v SMB dominuje), druhý QNAP, SAN na vyžádání.

**9. Pracnost:** **8–24 h na produktovou řadu výrobce** (odpovídá katalogu). Nasazení **0,5–1,5 h na zařízení** (1–3 h v katalogu je konzervativní odhad).

**10. Riziko:** věta z katalogu „zdravý RAID není záloha“ patří do zákaznického textu, kde už je.


## 4.4 MON-BKP · Monitoring zálohování

### Zákaznický pohled (položka katalogu)

| Pole | Obsah |
|---|---|
| ID | `MON-BKP` |
| Český název | Monitoring zálohování |
| Co monitorujeme | Výsledek každé zálohovací úlohy, varování, chyby, dobu běhu, objem dat a chybějící očekávaný výsledek. |
| Přínos | Selhání nebo tiché zastavení záloh nezůstane skryté; různé zálohovací produkty jsou sledovány centrálně. |
| Riziko | 🔴 Kritické. Nefunkční záloha se často projeví až ve chvíli, kdy je potřeba obnova. |
| Předpoklady na straně zákazníka | Jasný plán zálohování: rozsah, četnost a očekávané dokončení; report, API nebo stav, který lze číst. |
| Reporting | Úspěšnost, neúspěšné a chybějící běhy, poslední úspěšná záloha každé úlohy. |
| Omezení | Úspěšná zálohovací úloha nedokazuje, že data lze obnovit. |
| Hranice služby | Monitoring zahrnuje sběr dat, vyhodnocení a upozornění. Odstranění problému, správa, aktualizace a incident response nejsou součástí, pokud nejsou sjednány zvlášť. |

### Obchodní pohled

| Pole | Obsah |
|---|---|
| Cílový zákazník | Každý, kdo automaticky zálohuje kritické systémy. |
| Obchodní potenciál | Velmi vysoký (odhad, ověřit na portfoliu zákazníků) |
| Jednotka | zálohovací úloha / měsíc |
| Orientační cena | 150–300 Kč (odhad) |
| Produktizace (katalog) | 16–32 h první technologie, 6–20 h každý další konektor |
| Nasazení (katalog) | 0,5–2 h na úlohu |
| Navazující služby | Ověření obnovitelnosti (SRV-RESTORE), správa zálohování. |
| Doručení upozornění | Bez správy: určený kontakt zákazníka. Se správou Integrit: servisní proces Integritu (úkol v Planneru). |

### Technický návrh

**1. Rozsah:** pro každou zálohovací úlohu: poslední výsledek (úspěch/varování/selhání), text chyby, začátek/konec/doba běhu, přenesený a zpracovaný objem, **čas od posledního úspěšného běhu** vůči očekávanému plánu (detekce chybějícího běhu), kapacita repozitáře a výsledky kopií / offsite úloh. Volitelně: stav immutability/hardeningu a expirace licence zálohovacího produktu.

**Klíčový princip návrhu:** podstatným způsobem selhání je *ticho*: úloha neproběhla, report nepřišel nebo je agent nefunkční. Každá úloha proto kromě triggeru na stav dostane i **trigger na aktuálnost** („žádná úspěšná záloha za X hodin“). X se nastavuje pro každou úlohu podle plánu (`{$BKP.MAX.AGE:"<job>"}`, např. 26 h pro denní úlohy).

**2. Mechanismus ve verzi 7.0.31: jeden datový model, více konektorů**

Všechny konektory vytvářejí stejné položky pro každou úlohu (LLD podle názvu úlohy): `status`, `last_success_ts`, `duration`, `size`, `error_text`. Triggery a reporty jsou pak stejné bez ohledu na zálohovací produkt.

| Produkt | Varianty konektoru | Doporučení pro 7.0 |
|---|---|---|
| **Veeam Backup & Replication** | (a) Oficiální *Veeam Backup & Replication by HTTP* (REST API, port 9419), **součást sady šablon 7.0**; vyžaduje edici Veeam s REST API. (b) Oficiální *Veeam Backup Enterprise Manager by HTTP* tam, kde je Enterprise Manager. (c) Windows **Event Log** na serveru VBR přes aktivní položky `eventlog[]`, pro edice bez REST API. (d) PowerShell cmdlety (postupně se ruší; nepoužívat). | **(a) pro první vydání**, zabalené do datového modelu Integritu (LLD úloh → stav / poslední úspěch / doba běhu). **(c)** jako záloha pro Community Edition / samostatný Veeam Agent. |
| **Veeam Agent for Windows/Linux** (samostatný) | Event Log na chráněném stroji (Windows); log/journal na Linuxu | Na bázi událostí, stejný datový model |
| **Synology Active Backup for Business / Hyper Backup** | Veřejné API pro stav úloh neexistuje. Možnosti: e-mailové notifikace zpracované parserem Integritu; log DSM přes syslog na proxy; SNMP podrobnosti o úlohách neposkytuje | **E-mailový parser** nebo syslog |
| **Windows Server Backup** | Event Log (Microsoft-Windows-Backup) | Na bázi událostí |
| **Acronis Cyber Protect (Cloud)** | Oficiální šablony *Acronis Cyber Protect Cloud* (včetně varianty pro MSP) v sadě 7.0, z externí proxy | Oficiální |
| **Zálohovací produkty pro Microsoft 365** (např. Veeam Backup for M365, Microsoft 365 Backup a další) | API produktu nebo e-mailový report | Podle produktu |
| **Cokoli, co posílá jen e-mailové reporty** | **Obecný e-mailový parser**: reporty chodí do vyhrazené schránky (např. `backup-reports@integrit.cz`, aliasy pro jednotlivé zákazníky); služba parseru ji čte přes Graph (`Mail.Read` omezené na tuto schránku), pravidly pro jednotlivé produkty vytáhne úlohu/výsledek/čas a přes `zabbix_sender` je pošle do trapper položek Zabbixu | Framework se postaví jednou, pravidla pro každý produkt |

**3. Místo sběru:** proxy v lokalitě (event logy přes agenta na zálohovacím serveru, REST API), externí proxy (cloudová API, e-mailový parser).

**4. Předpoklady na straně zákazníka:** plán zálohování se seznamem úloh, plánem, rozsahem a retencí (katalog to už vyžaduje); přístup jen pro čtení k API nebo Event Logu; u produktů založených na e-mailu přesměrování nebo kopie reportů do schránky Integritu; určený vlastník každé úlohy.

**5. Výchozí triggery**

| Trigger | Závažnost | Výchozí hodnota |
|---|---|---|
| Úloha selhala | Vysoká | poslední stav = selhání |
| Úloha skončila s varováním | Varování (Průměrná při 3 po sobě) | – |
| **Žádný úspěšný běh v očekávaném okně** | Vysoká (Katastrofa po 2× okně) | `{$BKP.MAX.AGE}` pro každou úlohu |
| Žádná data z konektoru (report nepřišel, API selhává) | Průměrná | `nodata()` 2× interval plánu |
| Málo volného místa v repozitáři | Průměrná / Vysoká | < 15 % / < 5 % |
| Anomálie doby běhu | Varování | > 3× medián za 30 dní |
| Expirující licence zálohovacího produktu | Varování | < 30 dní |

**7. Report:** úspěšnost pro každou úlohu i celkově, neúspěšné a chybějící běhy s daty, poslední úspěšná záloha každé úlohy, trend kapacity repozitáře, trend doby běhu.

**8. První vydání:** Veeam (oficiální REST šablona, záložní varianta přes event log) + obecný e-mailový parser (pokryje Synology a dlouhý chvost ostatních). Windows Server Backup je s přístupem přes události téměř zdarma.

**9. Pracnost:** datový model + triggery + část reportu **12–16 h**; konektor Veeam (obalení oficiální šablony + záložní varianta přes event log) **8–12 h**; framework e-mailového parseru **32–48 h** + **6–12 h na sadu pravidel pro každý produkt**; API konektory **16–32 h každý**. Údaj z katalogu (16–32 h první technologie, 6–20 h každá další) je pro konektory realistický, ale nezahrnuje framework parseru. Nasazení **0,5–1 h na úlohu** zůstává platné, hlavně kvůli nastavení okna plánu pro každou úlohu.

**10. Rizika:** parsování e-mailů se rozbije, když výrobce změní formát (testy s uloženými vzorky pro každý produkt); přejmenování úloh vytváří nové LLD položky (proces změn u zákazníka); záměrně vypnuté úlohy je nutné vyloučit makrem, ne je nechat alertovat.


## 4.5 SRV-RESTORE · Ověření obnovitelnosti záloh

### Zákaznický pohled (položka katalogu)

| Pole | Obsah |
|---|---|
| ID | `SRV-RESTORE` |
| Český název | Ověření obnovitelnosti záloh |
| Co monitorujeme | Skutečnou obnovu vybrané zálohy, použitelnost dat, přístupová práva a funkčnost postupu obnovy. |
| Přínos | Prokáže, že zálohy jsou použitelné, a odhalí chybějící data, chybějící přístupy nebo nefunkční postup. |
| Riziko | 🔴 Kritické. Formálně úspěšná záloha může být při incidentu nepoužitelná. |
| Předpoklady na straně zákazníka | Plán zálohování, definovaný testovací scénář, izolované cílové prostředí, přístupy a kapacita. |
| Reporting | Protokol z testu s rozsahem, výsledkem a zjištěními. |
| Omezení | Dílčí test neověřuje všechny systémy ani úplný scénář obnovy po havárii. Jde o periodický servisní test, ne o průběžný monitoring. |
| Hranice služby | Monitoring zahrnuje sběr dat, vyhodnocení a upozornění. Odstranění problému, správa, aktualizace a incident response nejsou součástí, pokud nejsou sjednány zvlášť. |

### Obchodní pohled

| Pole | Obsah |
|---|---|
| Cílový zákazník | Zákazníci s kritickými daty, regulací nebo vyššími požadavky na kontinuitu. |
| Obchodní potenciál | Střední až vysoký (odhad, ověřit na portfoliu zákazníků) |
| Jednotka | test nebo testovací plán |
| Orientační cena | individuálně (odhad) |
| Produktizace (katalog) | 16–40 h |
| Nasazení (katalog) | 1–8+ h na test |
| Navazující služby | Plánování DR, správa zálohování. |
| Doručení upozornění | Bez správy: určený kontakt zákazníka. Se správou Integrit: servisní proces Integritu (úkol v Planneru). |

**Poznámka z analýzy:** Zákaznický text ve v1.1 to nazývá „průběžným monitoringem“; to je nutné opravit. Lépe se hodí do oddílu katalogu „navazující služby“.

### Technický návrh

**Povaha:** **odborná služba** (periodický test), ne průběžný monitoring. Zákaznický text v katalogu je potřeba opravit (uvádí „průběžně monitoruje“). Zabbix výsledek pouze *zaznamenává*, aby se zobrazil ve stejných reportech a aby mohl vyvolat upozornění, když je test po termínu.

**1. Rozsah:** obnova definovaného bodu obnovy do izolovaného cíle, ověření (boot, kontrola služeb, integrita souborů/DB, přihlášení do aplikace), změřená doba obnovy (RTO) a bod obnovy (RPO), protokol, úklid.

**2. Mechanismus**

| Část | Jak |
|---|---|
| Automatizované testy (kde je produkt podporuje) | Veeam **SureBackup** / SureReplica, Synology ABB „backup verification“. Výsledky jdou do MON-BKP jako jakákoli jiná úloha (stejný datový model) |
| Ruční / skriptované testy | Runbook + skripty v PowerShellu/Pythonu; technik zapíše výsledek do trapper položek Zabbixu (`restore.result`, `restore.rto_minutes`, `restore.date`, `restore.scope`) přes jednoduchý formulář nebo `zabbix_sender` |
| Kontrola termínu | Trigger „test obnovy po termínu“, když je `restore.date` starší než dohodnutý interval (např. čtvrtletně + 14 dní) |
| Protokol | Generuje ho stejný generátor reportů (kapitola 3.4) se zjištěními zadanými technikem |

**4. Předpoklady:** definovaný scénář pro každý systém, izolovaný cíl (sandboxová síť, dostatečná kapacita), přístupové údaje, dohodnutý interval a akceptační kritéria (RTO/RPO).

**5. Triggery:** test selhal (Vysoká); RTO nad cílovou hodnotou (Průměrná); test po termínu (Varování → Průměrná po 30 dnech).

**9. Pracnost:** produktizace **16–40 h** (odpovídá katalogu; převážně runbooky a šablony protokolů, část v Zabbixu 4–8 h). Realizace **2–8+ h na test**, cena individuálně, jak uvádí katalog.

**10. Otevřené body:** prefix ID `SRV-` (místo `MON-`) je správný, protože jde o službu, ale katalog by ji měl přesunout do oddílu „navazující služby“, aby ji zákazníci nevnímali jako monitoring.


## 4.6 MON-NET · Monitoring firewallu, routeru, VPN a internetu

### Zákaznický pohled (položka katalogu)

| Pole | Obsah |
|---|---|
| ID | `MON-NET` |
| Český název | Monitoring firewallu, routeru, VPN a internetu |
| Co monitorujeme | Dostupnost zařízení, WAN a záložní linky, rozhraní, chybovost, VPN a failover. |
| Přínos | Automatická detekce výpadku; rozliší poruchu zařízení, poruchu linky a poruchu vzdálené služby; historie pro reklamace u poskytovatele připojení. |
| Riziko | 🟠 Vysoké. Výpadek může odříznout celou lokalitu od internetu, cloudu a centrálních systémů. |
| Předpoklady na straně zákazníka | Zabezpečený způsob čtení stavu zařízení; seznam WAN linek, VPN a kritických cílů; dohodnutá definice výpadku vs. zhoršení. |
| Reporting | Dostupnost, výpadky, latence, přepnutí na záložní linku a stabilita VPN. |
| Omezení | Dostupnost zařízení nepotvrzuje, že fungují všechny aplikace. |
| Hranice služby | Monitoring zahrnuje sběr dat, vyhodnocení a upozornění. Odstranění problému, správa, aktualizace a incident response nejsou součástí, pokud nejsou sjednány zvlášť. |

### Obchodní pohled

| Pole | Obsah |
|---|---|
| Cílový zákazník | Každá firemní lokalita. |
| Obchodní potenciál | Velmi vysoký (odhad, ověřit na portfoliu zákazníků) |
| Jednotka | zařízení nebo lokalita / měsíc |
| Orientační cena | 300–800 Kč (odhad) |
| Produktizace (katalog) | 12–30 h na rodinu zařízení |
| Nasazení (katalog) | 1–3 h na zařízení |
| Navazující služby | Správa sítě, správa firewallu, eskalace k poskytovateli připojení. |
| Doručení upozornění | Bez správy: určený kontakt zákazníka. Se správou Integrit: servisní proces Integritu (úkol v Planneru). |

### Technický návrh

**1. Rozsah:** dostupnost a zdraví zařízení (CPU, paměť, teplota, napájecí zdroj, stav HA clusteru, expirace licencí/předplatného bezpečnostních funkcí), WAN linky (stav, propustnost, chyby/zahozené pakety, latence a ztrátovost k bráně poskytovatele a k internetovým cílům), záložní linka a **události failoveru**, VPN tunely (stav site-to-site, počet uživatelů vzdáleného přístupu přes VPN), aktuálně používaná veřejná IP adresa, stáří konfigurace/firmwaru a důležité události ze syslogu (neúspěšná přihlášení administrátora, HA failover, změna konfigurace).

**2. Mechanismus ve verzi 7.0.31**

| Oblast | Jak | Oficiální? |
|---|---|---|
| Zdraví zařízení a rozhraní | SNMP šablony výrobců (sada 7.0 obsahuje Cisco, MikroTik podle modelů, Juniper, pfSense, OPNsense, Check Point, FortiGate by SNMP i by HTTP, Palo Alto, Aruba, Huawei, Zyxel, Stormshield a další); záložně *Generic by SNMP* + *Interfaces by SNMP* | Většinou ano |
| Kvalita WAN, pohled zevnitř | ICMP z proxy v lokalitě na bránu poskytovatele a na 2–3 stabilní internetové cíle (`icmppingloss`, `icmppingsec`) | Vestavěné jednoduché kontroly |
| WAN, pohled zvenku | ICMP/TCP z **externích proxy** na veřejné IP adresy zákazníka; dva body měření pro potvrzení | Vestavěné |
| Detekce failoveru | Která WAN je aktivní: stav směrování/rozhraní přes SNMP, nebo veřejná IP viděná zevnitř (HTTP agent z proxy v lokalitě na endpoint Integritu typu „what is my IP“) porovnaná s primární IP | Vlastní řešení Integritu |
| VPN tunely | MIB výrobců (např. tabulky IPsec u Fortinetu/MikroTiku), kde jsou k dispozici; jinak ICMP z proxy v lokalitě *skrz* tunel na hosta na druhé straně | Kombinace |
| Bezpečnostní předplatné / licence | MIB nebo API výrobce (např. expirace smlouvy FortiGuard) | Podle výrobce |
| Syslog | Zařízení → rsyslog na proxy v lokalitě → soubor → položka `log[]` s regulárními výrazy Integritu pro každého výrobce | Vlastní řešení Integritu |
| SNMP trapy | snmptrapd na proxy → položky SNMP trapů | Vestavěný mechanismus |

**3. Místo sběru:** proxy v lokalitě (zevnitř), skupina externích proxy (zvenku).

**4. Předpoklady na straně zákazníka:** SNMPv3 jen pro čtení na zařízeních (a povolení, aby se k nim proxy dostala); seznam WAN linek s poskytovatelem, smluvní rychlostí a veřejnými IP adresami; seznam VPN tunelů s cílovou IP adresou za každým z nich; definice, které výpadky jsou „výpadek“ a které „zhoršení“ (katalog to vyžaduje).

**5. Výchozí triggery:** zařízení nedostupné (Katastrofa pro hlavní bránu lokality, protože je kořenem stromu závislostí); degradovaný HA cluster (Vysoká); WAN nefunkční (Vysoká) / ztrátovost paketů > 5 % po 10 min (Průměrná) / latence > 3× baseline (Varování); **přepnutí na záložní linku** (Vysoká, automaticky se vyřeší při návratu na primární linku, doba trvání se uvede v reportu); chyby na rozhraní > práh (Varování); využití > 90 % smluvní rychlosti po 15 min (Varování); VPN tunel nefunkční (Vysoká u site-to-site); bezpečnostní předplatné expiruje za < 30 dní (Varování); opakovaná neúspěšná přihlášení administrátora (Průměrná); změna konfigurace (Informace, report).

**6. Závislosti:** tato služba je kořenem pro každou lokalitu. Vše ostatní v lokalitě závisí na triggeru brány a brána závisí na dostupnosti proxy (kapitola 3.2.4).

**7. Report:** dostupnost jednotlivých linek a zařízení, výpadky s dobou trvání a příčinou (poskytovatel vs. zařízení vs. napájení), přepnutí na záložní linku, trend latence/ztrátovosti, stabilita VPN, špičky využití. Užitečné pro reklamace u poskytovatele, jak zmiňuje katalog.

**8. Varianty pro první vydání:** nejpravděpodobnější výrobce v zákaznické bázi Integritu je třeba potvrdit. Typický mix v českém SMB: **MikroTik, Fortinet, Sophos, Ubiquiti, Cisco/Meraki**. MikroTik a Fortinet mají silnou podporu SNMP; podpora SNMP u Sophosu je slabší (API/syslog). Doporučení: vybrat dva nejčastější v zákaznické bázi.

**9. Pracnost:** logika WAN/VPN/failoveru (nezávislá na výrobci) **16–24 h** jednorázově; **12–30 h na rodinu zařízení** (odpovídá katalogu). Nasazení **1–2 h na zařízení**; 1–3 h z katalogu je v pořádku.

## 4.7 MON-LAN · Monitoring switchů, Wi-Fi a PoE

### Zákaznický pohled (položka katalogu)

| Pole | Obsah |
|---|---|
| ID | `MON-LAN` |
| Český název | Monitoring switchů, Wi-Fi a PoE |
| Co monitorujeme | Dostupnost switchů a přístupových bodů, porty, uplinky, chybovost, vytížení a PoE. |
| Přínos | Rychlejší lokalizace poruchy; upozornění na výpadek kamer, telefonů nebo AP napájených přes PoE; přehled o přetížených částech sítě. |
| Riziko | 🟡 Střední až 🟠 Vysoké. Porucha může zastavit pracoviště, Wi-Fi nebo celou lokalitu. |
| Předpoklady na straně zákazníka | Spravovatelná zařízení, známá topologie a kritické porty, zabezpečený přístup ke správě. |
| Reporting | Dostupnost, incidenty na portech, chybovost, uplinky a problémy s PoE. |
| Omezení | Neověřuje kvalitu Wi-Fi signálu ve všech místech prostor. |
| Hranice služby | Monitoring zahrnuje sběr dat, vyhodnocení a upozornění. Odstranění problému, správa, aktualizace a incident response nejsou součástí, pokud nejsou sjednány samostatně. |

### Obchodní pohled

| Pole | Obsah |
|---|---|
| Cílový zákazník | Kanceláře, výroba, sklady a prodejny. |
| Obchodní potenciál | Vysoký (odhad, ověřit na portfoliu zákazníků) |
| Jednotka | switch nebo AP / měsíc |
| Orientační cena | switch 200–500 Kč; AP 100–250 Kč (odhad) |
| Produktizace (katalog) | 12–32 h na výrobce nebo řadu |
| Nasazení (katalog) | 0,5–2 h na zařízení (matice v1.0: AP 0,25–1 h) |
| Navazující služby | Správa sítě, Wi-Fi site survey. |
| Doručení upozornění | Bez správy: určený kontakt zákazníka. Se správou Integrit: servisní proces Integritu (úkol v Planneru). |

**Poznámka z analýzy:** v1.0 oceňovala AP jako samostatnou položku; v1.1 je sloučila. Rozhodnutí je otevřené; doporučujeme samostatnou položku.

### Technický návrh

**1. Rozsah:** dostupnost a zdraví switchů, uplinky a kritické porty (stav, chyby, zahozené pakety, vytížení, změny rychlosti/duplexu), změny topologie spanning tree, PoE rozpočet a poruchy PoE na jednotlivých portech, přístupové body (stav online, klienti, vytížení kanálu, je-li k dispozici), kontrolery.

**2. Mechanismus ve verzi 7.0.31**

| Oblast | Jak | Oficiální? |
|---|---|---|
| Switche | SNMP šablony výrobců ze sady 7.0 (Cisco, HPE/Aruba, MikroTik, Juniper, TP-Link, Netgear, D-Link, Zyxel, Extreme…) nebo *Generic by SNMP* + *Interfaces by SNMP* | Většinou ano |
| **Filtrování portů** (klíčový bod návrhu) | LLD filtry: monitorovat pouze porty, jejichž ifAlias odpovídá konvenci Integritu (např. `^(UPL|CRIT|SRV|AP)`), a všechny uplinky/LAG. Na přístupové porty se neupozorňuje, pouze se agregovaně reportují. Bez toho by každé vypnutí stolního PC vyvolalo „link down“ | Konfigurace |
| PoE | POWER-ETHERNET-MIB (RFC 3621): využitý vs. dostupný rozpočet, stav/porucha na jednotlivých portech | Vytvoří Integrit (obecně) |
| Wi-Fi s kontrolerem | UniFi (API kontroleru — komunitní šablony, nutné zpevnění ze strany Integritu); TP-Link Omada (API); **Cisco Meraki** (oficiální šablona Meraki HTTP v sadě 7.0, cloudové API); Aruba Instant On (omezené cloudové API) | Smíšeně |
| Wi-Fi bez kontroleru | SNMP na každém AP, pokud je podporováno, jinak pouze ICMP | – |

**3. Místo sběru:** proxy v lokalitě; zařízení spravovaná z cloudu (Meraki, UniFi cloud, Omada cloud) z externích proxy.

**4. Předpoklady na straně zákazníka:** SNMPv3 na switchích; zavedená konvence popisu portů (Integrit ji může zavést během onboardingu, což tvoří většinu času nasazení); účet pro API kontroleru; topologie (který switch visí na kterém uplinku) pro závislosti.

**5. Výchozí triggery:** switch nedostupný (Vysoká); výpadek uplinku/člena LAG (Vysoká); výpadek kritického portu (Průměrná); chyby/zahozené pakety nad prahem (Varování); vytížení uplinků > 90 % po 15 min (Varování); PoE rozpočet > 90 % (Varování); porucha PoE portu (Průměrná); AP offline (Průměrná; Vysoká, pokud je v lokalitě offline > 30 % AP); kontroler nedostupný (Průměrná).

**6. Závislosti:** přístupové switche závisí na core/uplinku; AP závisí na svém switchi.

**7. Report:** dostupnost, incidenty na portech, trendy chybovosti, špičky vytížení uplinků, využití PoE, dostupnost AP.

**8. První vydání:** jeden výrobce switchů + UniFi (v SMB velmi rozšířené) nebo Meraki, podle zákaznické báze.

**9. Pracnost:** **12–32 h na výrobce/řadu** (odpovídá katalogu), **16–32 h na platformu Wi-Fi kontroleru**. Nasazení: **0,5–2 h na switch** (převážně popis portů), **0,1–0,25 h na AP** za kontrolerem. Matice v1.0 uváděla u AP 0,25–1 h; s kontrolerem je to méně.

**10. Otevřené:** rozhodnout, zda budou AP samostatnou cenovou položkou (v1.0), nebo sloučené (v1.1). Technicky se chovají jako samostatná jednotka, proto doporučujeme samostatnou cenovou položku.


## 4.8 MON-UPS · Monitoring UPS a napájení

### Zákaznický pohled (položka katalogu)

| Pole | Obsah |
|---|---|
| ID | `MON-UPS` |
| Český název | Monitoring UPS a napájení |
| Co monitorujeme | Dostupnost UPS, baterie, zátěž, výdrž, výpadek vstupního napájení a autotesty. |
| Přínos | Upozornění na opotřebenou baterii; záznam výpadků napájení; plánovaná výměna baterie místo havarijní. |
| Riziko | 🔴 Kritické. Selhání UPS může způsobit tvrdé vypnutí, poškození dat a výpadek provozu. |
| Předpoklady na straně zákazníka | Síťová management karta nebo komunikační modul; známá chráněná zařízení; definovaná minimální výdrž. |
| Reporting | Výpadky napájení, stav baterie, zátěž, výdrž a testy. |
| Omezení | Samotný monitoring nezajišťuje bezpečné vypnutí serverů. |
| Hranice služby | Monitoring zahrnuje sběr dat, vyhodnocení a upozornění. Odstranění problému, správa, aktualizace a incident response nejsou součástí, pokud nejsou sjednány samostatně. |

### Obchodní pohled

| Pole | Obsah |
|---|---|
| Cílový zákazník | Servery, NAS, výroba a síťová infrastruktura. |
| Obchodní potenciál | Vysoký (odhad, ověřit na portfoliu zákazníků) |
| Jednotka | UPS / měsíc |
| Orientační cena | 200–500 Kč (odhad) |
| Produktizace (katalog) | 8–20 h na produktovou řadu |
| Nasazení (katalog) | 1–3 h na UPS |
| Navazující služby | Orchestrace vypínání (SRV-SHUTDOWN v Části 5), výměna baterií. |
| Doručení upozornění | Bez správy: určený kontakt zákazníka. Se správou Integrit: servisní proces Integritu (úkol v Planneru). |

### Technický návrh

**1. Rozsah:** dostupnost management karty, stav vstupního napájení (běh na baterii), kapacita baterie, stav nabíjení, indikátor nutnosti výměny baterie, stáří baterie / datum poslední výměny, zátěž v %, odhadovaná výdrž vs. požadovaná výdrž, stav výstupu, výsledky autotestů, teplota, události napájení.

**2. Mechanismus ve verzi 7.0.31**

| Výrobce | Jak | Oficiální? |
|---|---|---|
| APC (Network Management Card) | Oficiální rodina šablon *APC UPS by SNMP* | Ano |
| Eaton, Legrand, Socomec, Riello a další | Standardní **UPS-MIB (RFC 1628)** — jedna šablona Integritu „Generic UPS-MIB“ pokryje většinu karet; MIB výrobce jen pro doplňkové údaje | Integrit vytvoří jednou |
| UPS pouze s USB (bez karty) | Agent 2 na chráněném serveru + NUT (`upsc`) přes UserParameter | Vytvoří Integrit |
| Události | SNMP trapy na proxy pro „běh na baterii“ (okamžitě), polling jako záloha | – |

**3. Místo sběru:** proxy v lokalitě.

**4. Předpoklady na straně zákazníka:** síťová management karta (nebo USB + server), seznam chráněných zařízení, požadovaná minimální výdrž pro každou UPS (řídí trigger na výdrž), datum instalace baterie.

**5. Výchozí triggery:** UPS nedostupná (Průměrná); běh na baterii (Vysoká, Katastrofa, pokud je výdrž < požadované); slabá baterie (Katastrofa); vyměnit baterii (Vysoká); přetížení > 90 % (Vysoká), trvale > 80 % (Varování); výdrž < `{$UPS.RUNTIME.MIN}` (Vysoká); autotest selhal (Vysoká); stáří baterie > 4 roky (Varování, report).

**6. Závislosti:** „lokalita nedostupná“ a těsně předtím „UPS na baterii“ je nejsilnějším signálem výpadku napájení. V reportu je korelovat.

**7. Report:** události napájení (počet, doba trvání), zdraví a stáří baterie, trend zátěže, výdrž vs. požadavek, autotesty.

**8. První vydání:** APC + generická UPS-MIB pokryje téměř všechny spravované UPS.

**9. Pracnost:** **12–16 h** pro generickou šablonu + APC (katalog: 8–20 h na řadu; potřeba je méně řad). Nasazení **0,5–1 h na UPS** s kartou.

**10. Otevřené:** katalog uvádí, že monitoring nezaručuje bezpečné vypnutí. Orchestrace vypínání (PowerChute, Eaton IPM, NUT) je navržena jako SRV-SHUTDOWN (kapitola 5.6.4).


## 4.9 MON-WEB · Základní monitoring webu

### Zákaznický pohled (položka katalogu)

| Pole | Obsah |
|---|---|
| ID | `MON-WEB` |
| Český název | Základní monitoring webu |
| Co monitorujeme | Dostupnost webu, odpověď serveru, dobu odezvy a SSL/TLS certifikát. |
| Přínos | Automatická detekce výpadku; předchází vypršení certifikátu; historie stability. |
| Riziko | 🟡 Střední. Nedostupný nebo nedůvěryhodný web může poškodit obchod i důvěru. |
| Předpoklady na straně zákazníka | Známá URL a očekávaná odpověď; veřejná dostupnost; ověřené chování ochranných vrstev (WAF, ochrana proti botům). |
| Reporting | Dostupnost, doba odezvy a výpadky. |
| Omezení | Nepotvrzuje, že fungují formuláře, přihlášení nebo obchodní procesy. |
| Hranice služby | Monitoring zahrnuje sběr dat, vyhodnocení a upozornění. Odstranění problému, správa, aktualizace a incident response nejsou součástí, pokud nejsou sjednány samostatně. |

### Obchodní pohled

| Pole | Obsah |
|---|---|
| Cílový zákazník | Každý provozovatel veřejného webu. |
| Obchodní potenciál | Velmi vysoký (odhad, ověřit na portfoliu zákazníků) |
| Jednotka | web / měsíc |
| Orientační cena | 100–200 Kč (odhad) |
| Produktizace (katalog) | 6–12 h |
| Nasazení (katalog) | 10–30 min na web |
| Navazující služby | MON-WEB-FUNC, MON-WP, webhosting / správa webu. |
| Doručení upozornění | Bez správy: určený kontakt zákazníka. Se správou Integrit: servisní proces Integritu (úkol v Planneru). |

**Poznámka z analýzy:** v1.0 navrhuje sdružení s MON-DNS do balíčku „Web Basic“.

### Technický návrh

**1. Rozsah:** dostupnost HTTP(S), stavový kód, doba odezvy, očekávaný obsah (klíčové slovo), řetězec přesměrování (http→https, www), platnost/vypršení/řetězec TLS certifikátu a shoda názvu hostitele, záložní kontrola TCP 443.

**2. Mechanismus ve verzi 7.0.31**

| Oblast | Jak | Oficiální? |
|---|---|---|
| Dostupnost, stav, doba odezvy, klíčové slovo | Položka HTTP agent (preferováno: jeden požadavek, stavový kód + regex na tělo odpovědi v preprocessingu) nebo jednokrokový webový scénář | Vestavěné |
| Certifikát | *Website certificate by Zabbix agent 2* (plugin WebCertificate v Agent 2 na externí proxy) | Ano |
| Záložní kontrola | `net.tcp.service[https]`, když je HTTP kontrola blokována | Vestavěné |
| Dva body měření | Stejné položky ze dvou proxy; trigger výpadku se spustí, jen když selžou obě | Návrh Integritu |

**4. Předpoklady:** seznam URL, očekávaný stavový kód a klíčové slovo pro každou URL; povolení (allowlist) IP adres Integritu na WAF/hostingu; kontakt.

**5. Triggery:** web nedostupný z obou míst po 3 kontroly (Vysoká); nedostupný z jednoho místa (Varování, pouze interně); chybný stav / chybějící klíčové slovo (Vysoká); doba odezvy > `{$WEB.RESP.MAX}` (výchozí 3 s) v průměru za 10 min (Varování); certifikát vyprší za < 21 dní (Varování), za < 7 dní (Vysoká), neplatný / neshoda názvu hostitele (Vysoká).

**7. Report:** dostupnost v %, výpadky s dobou trvání, trend doby odezvy, stav certifikátu.

**9. Pracnost:** **8–12 h** (katalog 6–12 h). Nasazení **10–20 min na web** pomocí nástroje pro evidenci.


## 4.10 MON-DNS · Monitoring domény, DNS a certifikátu

### Zákaznický pohled (položka katalogu)

| Pole | Obsah |
|---|---|
| ID | `MON-DNS` |
| Český název | Monitoring domény, DNS a certifikátu |
| Co monitorujeme | Expiraci domény, vybrané DNS záznamy a platnost certifikátu. |
| Přínos | Předchází výpadkům kvůli zapomenutému prodloužení nebo chybné změně; upozorňuje na změny; přehled o celém portfoliu domén. |
| Riziko | 🟠 Vysoké. Expirovaná doména nebo chybný DNS záznam může vyřadit web, e-mail i další služby. |
| Předpoklady na straně zákazníka | Úplný seznam domén a subdomén, jejich účel a očekávané DNS hodnoty. |
| Reporting | Blížící se expirace a změny kritických DNS záznamů. |
| Omezení | Neplatí ani neprodlužuje doménu. |
| Hranice služby | Monitoring zahrnuje sběr dat, vyhodnocení a upozornění. Odstranění problému, správa, aktualizace a incident response nejsou součástí, pokud nejsou sjednány samostatně. |

### Obchodní pohled

| Pole | Obsah |
|---|---|
| Cílový zákazník | Kdokoli s vlastními doménami a veřejnými službami. |
| Obchodní potenciál | Velmi vysoký; vhodné do balíčku s MON-WEB (odhad, ověřit na portfoliu zákazníků) |
| Jednotka | doména / měsíc |
| Orientační cena | 50–150 Kč (odhad) |
| Produktizace (katalog) | 8–20 h |
| Nasazení (katalog) | 10–30 min na doménu |
| Navazující služby | Správa domén, MON-MAIL (Část 5). |
| Doručení upozornění | Bez správy: určený kontakt zákazníka. Se správou Integrit: servisní proces Integritu (úkol v Planneru). |

### Technický návrh

**1. Rozsah:** expirace registrace domény, zámek/stav u registrátora, sada nameserverů a konzistence delegace, očekávané hodnoty kritických záznamů (A/AAAA, MX, SPF, DMARC, selektory DKIM, CNAME pro M365), neočekávané změny, **platnost DNSSEC** (u domén .cz velmi rozšířené; vypršení podpisu nebo porušený řetězec učiní doménu nedostupnou) a v případě potřeby certifikáty na jiných než webových službách (SMTP STARTTLS, IMAPS, LDAPS).

**2. Mechanismus ve verzi 7.0.31**

| Oblast | Jak |
|---|---|
| Expirace domény | **RDAP** přes HTTP agent (JSON) pro TLD s RDAP (včetně .cz přes CZ.NIC a většiny gTLD). Pro TLD bez použitelného RDAP externí WHOIS skript na externí proxy. Denní interval |
| DNS záznamy | Simple checks `net.dns.record[]` proti autoritativním nameserverům a veřejnému resolveru; porovnání s makrem očekávané hodnoty; detekce změn pomocí `change()` nad normalizovanou hodnotou |
| DNSSEC | Externí skript (např. `delv` / nástroje ldns) na externí proxy: stav validace a počet dní do vypršení RRSIG |
| Záznamy pro zabezpečení e-mailu | SPF/DMARC rozparsované do položek (přítomnost, politika, syntaxe) |
| Certifikáty (mimo web) | Skript s `openssl s_client -starttls` pro SMTP/IMAP/LDAPS |

**4. Předpoklady:** úplný seznam domén a subdomén s účelem a očekávanými DNS hodnotami (katalog to již vyžaduje). Kdo jednotlivé domény prodlužuje (vlastník účtu u registrátora).

**5. Triggery:** doména vyprší za < 30 dní (Průměrná), za < 7 dní (Katastrofa); stav u registrátora neočekávaně umožňuje převod (Varování); kritický záznam se liší od očekávané hodnoty (Vysoká); záznam změněn (Informace + report); nekonzistence NS (Průměrná); selhávající validace DNSSEC (Katastrofa); vypršení RRSIG za < 3 dny (Vysoká); chybějící nebo neplatný DMARC/SPF (Varování).

**7. Report:** blížící se expirace, změny záznamů za měsíc, stav DNSSEC a zabezpečení e-mailu.

**9. Pracnost:** **16–24 h** (katalog 8–20 h; DNSSEC a práce s RDAP/WHOIS něco přidají). Nasazení **10–30 min na doménu** (odpovídá).

**Sdružování:** MON-WEB + MON-DNS sdílejí stejné proxy i evidenci, takže balíček „Web Basic“ (jak navrhovala v1.0) je přirozený.


## 4.11 MON-WP · Rozšířený monitoring WordPressu

### Zákaznický pohled (položka katalogu)

| Pole | Obsah |
|---|---|
| ID | `MON-WP` |
| Český název | Rozšířený monitoring WordPressu |
| Co monitorujeme | Technický stav WordPressu: verzi jádra, aktualizace pluginů a plánované úlohy (WP-Cron). |
| Přínos | Upozornění na zastaralé komponenty a technické problémy; centrální přehled nad portfoliem webů. |
| Riziko | 🟠 Vysoké. Zastaralé komponenty mohou způsobit chyby, výpadky nebo bezpečnostní riziko. |
| Předpoklady na straně zákazníka | Podporovaná instalace, možnost nainstalovat monitorovací komponentu, technický přístup a známý vlastník webu. |
| Reporting | Souhrnný stav webů, aktualizací a problémů. |
| Omezení | Nejde o bezpečnostní audit, antivirovou kontrolu ani záruku, že web není kompromitován. |
| Hranice služby | Monitoring zahrnuje sběr dat, vyhodnocení a upozornění. Odstranění problému, správa, aktualizace a incident response nejsou součástí, pokud nejsou sjednány samostatně. |

### Obchodní pohled

| Pole | Obsah |
|---|---|
| Cílový zákazník | Provozovatelé jednoho či více webů na WordPressu. |
| Obchodní potenciál | Vysoký (odhad, ověřit na portfoliu zákazníků) |
| Jednotka | instalace / měsíc |
| Orientační cena | 300–500 Kč (odhad) |
| Produktizace (katalog) | 12–24 h |
| Nasazení (katalog) | 0,5–1,5 h na web |
| Navazující služby | Správa a aktualizace WordPressu, hosting. |
| Doručení upozornění | Bez správy: určený kontakt zákazníka. Se správou Integrit: servisní proces Integritu (úkol v Planneru). |

**Poznámka z analýzy:** Produktizace je v katalogu podhodnocena (vlastní plugin: 40–80 h, viz technický návrh). Ve složce dokumentů Monitoring je zip s pluginem wp-zabbix, který může posloužit jako výchozí bod.

### Technický návrh

**1. Rozsah:** verze jádra a dostupná aktualizace (bezpečnostní vs. minor), pluginy a šablony s dostupnými aktualizacemi (počty a názvy), pluginy se známými zranitelnostmi (volitelně, přes zdroj dat o zranitelnostech), verze PHP a DB, zdraví WP-Cron (opožděné události), zapnutý debug režim, povolená editace souborů, počet administrátorů, stav Site Health, dostupnost endpointu.

**2. Mechanismus ve verzi 7.0.31**

| Varianta | Jak | Výhody / nevýhody |
|---|---|---|
| **A. Monitorovací plugin Integritu** (přístup katalogu) | Malý plugin pro WordPress zpřístupňující `/wp-json/integrit/v1/status`, autentizovaný tajemstvím pro každý web (HMAC hlavička). Master položka HTTP agent v Zabbixu + závislé položky přes JSONPath; tajemství jako secret makro | ✔ Funguje na jakémkoli hostingu, bohatá data. ✘ Integrit musí WP plugin napsat, zabezpečit, aktualizovat a podporovat (bezpečnostní expozice na webech zákazníků) |
| B. WP-CLI přes agenta | Tam, kde hosting provozuje Integrit: UserParameter v Agent 2 spouštějící `wp core check-update`, `wp plugin list --update=available` | ✔ Bez pluginu. ✘ Pouze na serverech, které Integrit spravuje |
| C. Existující nástroj pro správu jako zdroj | Pokud Integrit již používá MainWP / ManageWP / InfiniteWP, centrálně načítat jeho API | ✔ Žádný kód na jednotlivých webech. ✘ Závisí na API daného nástroje |
| D. Data o zranitelnostech | Zdroje WPScan / Patchstack / Wordfence Intelligence porovnávané se seznamem pluginů | Volitelné, nutné ověřit licencování |

**Doporučení:** A pro weby hostované zákazníkem, B tam, kde hostuje Integrit. Plugin musí být minimální (pouze čtení, žádné vzdálené akce), s podepsanými vydáními, po code review a automaticky aktualizovaný vlastním aktualizačním kanálem Integritu.

**4. Předpoklady:** administrátorský přístup do WP pro instalaci pluginu (nebo shell na hostingu pro B), kontakt na vlastníka, politika aktualizací (kdo aktualizuje: zákazník, nebo Integrit v rámci správy).

**5. Triggery:** endpoint nedostupný / selhání autentizace (Průměrná); bezpečnostní aktualizace jádra dostupná > 3 dny (Vysoká); čekající aktualizace pluginů > 14 dní (Varování) / plugin se známou zranitelností (Vysoká); WP-Cron opožděn > 1 h (Průměrná); zapnutý debug režim v produkci (Varování); verze PHP po skončení podpory (Varování).

**7. Report:** tabulka stavu jednotlivých webů napříč portfoliem zákazníka, backlog aktualizací, problémy.

**9. Pracnost:** **40–80 h** včetně vývoje pluginu, bezpečnostní revize a aktualizačního kanálu (12–24 h v katalogu je příliš málo). Průběžná údržba cca 2–4 h/měsíc kvůli kompatibilitě s WP. Nasazení **0,5–1 h na web** (odpovídá).

**10. Riziko:** plugin se stane součástí útočné plochy Integritu. Pokud Integrit nechce vlastní plugin vlastnit, alternativou jsou varianty B/C, případně se služba omezí na weby hostované Integritem.


## 4.12 MON-WEB-FUNC · Funkční monitoring webu a formulářů

### Zákaznický pohled (položka katalogu)

| Pole | Obsah |
|---|---|
| ID | `MON-WEB-FUNC` |
| Český název | Funkční monitoring webu a formulářů |
| Co monitorujeme | Konkrétní stránku nebo proces, očekávaný obsah, formulář, jeho odeslání a volitelně doručení testovací zprávy. |
| Přínos | Ověřuje důležitou funkci, kterou základní kontrola dostupnosti nevidí; chrání poptávky a objednávky. |
| Riziko | 🟠 Vysoké. Nefunkční formulář může tiše ztrácet poptávky. |
| Předpoklady na straně zákazníka | Definovaný scénář, očekávaný výsledek, testovací data a bezpečné opakování. |
| Reporting | Dostupnost scénáře, incidenty a doba odezvy. |
| Omezení | Ověřuje pouze definovaný scénář; změny webu mohou vyžadovat úpravu testu. |
| Hranice služby | Monitoring zahrnuje sběr dat, vyhodnocení a upozornění. Odstranění problému, správa, aktualizace a incident response nejsou součástí, pokud nejsou sjednány samostatně. |

### Obchodní pohled

| Pole | Obsah |
|---|---|
| Cílový zákazník | Formuláře, rezervace, objednávky a další kritické interakce. |
| Obchodní potenciál | Střední až vysoký (odhad, ověřit na portfoliu zákazníků) |
| Jednotka | scénář / měsíc |
| Orientační cena | 200–800 Kč (odhad) |
| Produktizace (katalog) | 12–30 h |
| Nasazení (katalog) | 1–6 h na scénář |
| Navazující služby | Vývoj a údržba webu. |
| Doručení upozornění | Bez správy: určený kontakt zákazníka. Se správou Integrit: servisní proces Integritu (úkol v Planneru). |

### Technický návrh

**1. Rozsah:** vícekrokové uživatelské průchody (otevření stránky, vyplnění formuláře, odeslání, kontrola potvrzení), přihlašovací procesy, e-shop od vložení do košíku po pokladnu až před platbu, volitelně potvrzení, že testovací poptávka byla doručena e-mailem.

**2. Mechanismus ve verzi 7.0.31**

| Varianta | Jak | Vhodnost |
|---|---|---|
| **Položka Browser (novinka v 7.0)** | Skutečný prohlížeč řízený JavaScriptem přes **Selenium WebDriver** (kontejner s Chrome vedle externí proxy; `WebDriverURL` v konfiguraci proxy); vícekrokové skripty, časy jednotlivých kroků, snímek obrazovky při selhání. Výchozím bodem je oficiální šablona *Website by Browser* | ✔ Zvládá weby a formuláře s množstvím JS; nativně v 7.0 |
| Webový scénář | Vícekrokové HTTP bez JavaScriptu (cookies, proměnné, POST) | ✔ Levné pro jednoduché formuláře renderované na serveru; ✘ selhává na webech s JS/SPA |
| Potvrzení doručení | Testovací poptávky adresované do testovací schránky Integritu; kontrola přes Graph (položka Script) potvrdí doručení do N minut | Vytvoří Integrit |

**4. Předpoklady (kritické):** dohodnutý scénář a očekávaný výsledek; **způsob označení testovacích odeslání** (testovací příznak, vyhrazený testovací e-mail nebo skryté pole), aby nezaneřáďovala CRM/leady zákazníka; výjimka z CAPTCHA pro IP adresy Integritu nebo testovací klíč; dohodnutá frekvence (každých 15–60 min; častější kontrolu formuláře potřebují jen výjimečně); proces oznamování změn (redesign webu skripty rozbije).

**5. Triggery:** scénář selhal dvakrát po sobě z obou míst (Vysoká); doba trvání kroku > práh (Varování); potvrzovací e-mail nedoručen do 15 min (Vysoká).

**7. Report:** dostupnost scénáře, selhání se snímky obrazovky, časy jednotlivých kroků.

**9. Pracnost:** platforma (WebDriver, knihovna skriptů, kontrola schránky) **16–24 h** jednorázově; **2–8 h na scénář**. Katalog: 12–30 h produktizace, 1–6 h na scénář; blízko. Skrytým nákladem je údržba skriptů po změnách webu, která by se měla účtovat jako změnová práce.

**10. Rizika:** CAPTCHA a ochrana proti botům; testy pokladny se musí zastavit před platbou; GDPR u testovacích dat.


## 4.13 MON-EPS · Monitoring endpoint security

### Zákaznický pohled (položka katalogu)

| Pole | Obsah |
|---|---|
| ID | `MON-EPS` |
| Český název | Monitoring endpoint security |
| Co monitorujeme | Komunikaci zařízení s bezpečnostní konzolí, stav ochrany, neaktivní zařízení a závažné události. |
| Přínos | Odhalí zařízení mimo centrální správu; jeden přehled kritických bezpečnostních událostí. |
| Riziko | 🟠 Vysoké. Zařízení mimo centrální správu mohou zůstat bez záplat nebo bez ochrany. |
| Předpoklady na straně zákazníka | Centrální bezpečnostní nástroj, dostupný report/API, definovaná doba pro stav „nekomunikuje“. |
| Reporting | Aktivní a neaktivní zařízení, závažné události. |
| Omezení | Nejde o SOC/SIEM ani o průběžnou analýzu všech událostí. |
| Hranice služby | Monitoring zahrnuje sběr dat, vyhodnocení a upozornění. Odstranění problému, správa, aktualizace a incident response nejsou součástí, pokud nejsou sjednány samostatně. |

### Obchodní pohled

| Pole | Obsah |
|---|---|
| Cílový zákazník | ESET PROTECT nebo jiná centrální ochrana koncových zařízení. |
| Obchodní potenciál | Vysoký u spravovaných zákazníků (odhad, ověřit na portfoliu zákazníků) |
| Jednotka | koncové zařízení nebo tenant / měsíc |
| Orientační cena | 20–60 Kč za koncové zařízení, minimum 300–800 Kč za tenant (odhad) |
| Produktizace (katalog) | 16–40 h na platformu |
| Nasazení (katalog) | 2–6 h na konzoli nebo tenant |
| Navazující služby | Správa koncových zařízení, MON-MDM (Část 5), spravovaná bezpečnost. |
| Doručení upozornění | Bez správy: určený kontakt zákazníka. Se správou Integrit: servisní proces Integritu (úkol v Planneru). |

### Technický návrh

**1. Rozsah:** zařízení, která do konzole nehlásí déle než N dní, stav ochrany (vypnutá ochrana v reálném čase, zastaralý detekční engine/moduly, zastaralý produkt, vyžadovaný restart), aktivní/nevyřešené detekce (závažnost, zařízení, hrozba), zařízení bez agenta (lze-li porovnat s inventářem, např. Entra/Intune nebo AD), využití licencí vs. nárok, zdraví samotné konzole.

**Volba návrhu:** **agregovat po tenantech, detail na vyžádání.** Vytvářet sadu položek Zabbixu pro každé koncové zařízení (tisíce) je nákladné a hlučné. Místo toho sbírat po tenantech: počty (celkem, nekomunikující, nechráněná, zastaralá, s aktivními hrozbami) a seznamy (JSON uložený jako text, zobrazený v reportu). Problémy na úrovni zařízení vyvolávat pouze pro **aktivní hrozby** a **vypnutou ochranu**, a to pomocí LLD omezeného na dotčená zařízení.

**2. Mechanismus ve verzi 7.0.31**

| Platforma | Přístup | Poznámky |
|---|---|---|
| **ESET PROTECT Cloud** | Veřejné API ESET Connect (OAuth) | Preferováno pro ESET; pokrývá zařízení i detekce |
| **ESET PROTECT On-Prem** | Žádné ekvivalentní REST API. Možnosti: dotaz **ODBC** pouze pro čtení do databáze konzole (MS SQL/MySQL) z proxy v lokalitě; export detekcí přes syslog na proxy | ODBC funguje, ale závisí na interním schématu DB (riziko při upgradech konzole) |
| **Microsoft Defender for Endpoint / Business** | Defender API / Graph Security (aplikace: čtení zařízení, čtení upozornění) | Zapadá do modelu tenantových aplikací Integritu (viz M365) |
| Sophos Central, Bitdefender GravityZone a další | Partnerská API výrobců | Na vyžádání |

**3. Místo sběru:** externí proxy (cloudové konzole), proxy v lokalitě (on-prem ESET přes ODBC/syslog).

**4. Předpoklady:** API klient s oprávněním pouze pro čtení pro každý tenant (nebo API na úrovni partnera/MSP, pokud je Integrit MSP partnerem ESET, což dává jedny přihlašovací údaje pro všechny zákazníky), definovaný práh pro „nekomunikuje“ (požadavek katalogu), definované mapování závažností.

**5. Triggery:** aktivní detekce vysoké závažnosti nevyřešená > 30 min (Vysoká); jakákoli detekce (Informace + report); vypnutá ochrana na zařízení (Vysoká); nekomunikující zařízení > `{$EPS.STALE.DAYS}` (výchozí 7) nad N nebo % (Průměrná); zastaralé moduly > 3 dny (Varování); využití licencí > 95 % (Varování) / překročení (Průměrná); API/konzole nedostupná (Průměrná).

**7. Report:** počty aktivních/neaktivních zařízení a trend, seznamy nekomunikujících a nechráněných zařízení, detekce za měsíc s jejich vyřešením, využití licencí.

**8. První vydání:** ESET (cíl jmenovaný v katalogu): nejprve Cloud přes API; on-prem jen tehdy, je-li v zákaznické bázi běžný. Defender jako druhý, pokud zákazníci Integritu používají M365 Business Premium.

**9. Pracnost:** **24–40 h na platformu** (katalog 16–40 h). Nasazení **1–3 h na tenant** (katalog 2–6 h; s API na úrovni MSP méně).

**10. Pozicování:** omezení v katalogu „nejde o SOC/SIEM“ je správné a musí zůstat v zákaznickém textu. Eskalace detekce mimo pracovní dobu vyžaduje rozhodnutí; právě zde zákazníci předpokládají SOC.


## 4.14 MON-M365 · Monitoring Microsoft 365 a licencí

### Zákaznický pohled (položka katalogu)

| Pole | Obsah |
|---|---|
| ID | `MON-M365` |
| Český název | Monitoring Microsoft 365 a licencí |
| Co monitorujeme | Dostupné, přiřazené a nevyužité licence, evidovaná obnovení a vybrané stavy tenantu. |
| Přínos | Zabrání placení za nevyužité licence; přehled o kapacitě; včasné upozornění na nedostatek. |
| Riziko | 🟡 Střední. Chybná evidence licencí vede k vícenákladům nebo k nedostatku licencí. |
| Předpoklady na straně zákazníka | Definovaný rozsah tenantu, zabezpečený aplikační přístup a dohodnuté prahy. |
| Reporting | Licence, nevyužitá kapacita, změny a obnovení. |
| Omezení | Nenakupuje, neruší ani právně neposuzuje licence. |
| Hranice služby | Monitoring zahrnuje sběr dat, vyhodnocení a upozornění. Odstranění problému, správa, aktualizace a incident response nejsou součástí, pokud nejsou sjednány samostatně. |

### Obchodní pohled

| Pole | Obsah |
|---|---|
| Cílový zákazník | Tenanty Microsoft 365, zejména s proměnlivým počtem uživatelů. |
| Obchodní potenciál | Vysoký; část lépe zapadá do správy tenantu (odhad, ověřit na portfoliu zákazníků) |
| Jednotka | tenant / měsíc |
| Orientační cena | 300–1 500 Kč (odhad) |
| Produktizace (katalog) | 24–60 h |
| Nasazení (katalog) | 2–6 h na tenant |
| Navazující služby | Správa tenantu, optimalizace licencí, MON-IDSEC (Část 5). |
| Doručení upozornění | Bez správy: určený kontakt zákazníka. Se správou Integrit: servisní proces Integritu (úkol v Planneru). |

**Poznámka z analýzy:** „Vybrané stavy tenantu“ nebyly definovány; technický návrh navrhuje konkrétní sadu.

### Technický návrh

**1. Rozsah:**
- **Licence:** pro každý SKU zakoupené / přiřazené / dostupné; licence přiřazené zakázaným nebo neaktivním uživatelům (přihlášení > 30/60/90 dní); předplatná blížící se obnovení/vypršení/pozastavení.
- **Stav tenantu (definuje vágní „vybrané stavy tenantu“)**, navržená sada:
  - Incidenty Service Health ovlivňující tenant
  - Stáří poslední synchronizace Entra Connect / Cloud Sync (hybridní zákazníci)
  - Vypršení tajemství/certifikátů registrací aplikací
  - Počet globálních administrátorů (příliš mnoho / příliš málo)
  - Uživatelé bez registrace MFA (počet)
  - Trend Microsoft Secure Score
  - Ověření domén / zdraví DNS pro M365 (překrývá se s MON-DNS)

**2. Mechanismus ve verzi 7.0.31**
- Oficiální šablona *Microsoft 365 reports by HTTP* **je součástí sady šablon 7.0**. Použít ji pro Service Health a reporty využití (aktivita Teams, Exchange, OneDrive, SharePoint). **Nepokrývá** inventář licencí, obnovení ani hygienu tenantu, proto je doplní **šablona Integritu nad položkami Script**.
- Endpointy Graph: `/subscribedSkus` (licence), `/directory/subscriptions` (data obnovení), `/users?$select=assignedLicenses,accountEnabled,signInActivity` (neaktivní uživatelé s licencí; `signInActivity` vyžaduje Entra ID P1 v tenantu zákazníka), `/admin/serviceAnnouncement/healthOverviews`, `/organization` (onPremisesLastSyncDateTime), `/applications` (vypršení přihlašovacích údajů), `/reports/authenticationMethods/userRegistrationDetails` (registrace MFA), `/security/secureScores`.
- **Oprávnění (aplikační, s admin consentem, pouze pro čtení):** Organization.Read.All, LicenseAssignment.Read.All nebo Directory.Read.All, User.Read.All, AuditLog.Read.All (pro signInActivity), ServiceHealth.Read.All, Application.Read.All, Reports.Read.All, SecurityEvents.Read.All. Konečnou sadu s nejnižšími oprávněními potvrdit v labu.
- **Model přístupu k více tenantům:**

| Varianta | Jak | Hodnocení |
|---|---|---|
| Jedna **multi-tenant aplikace Entra** vlastněná Integritem, s admin consentem v každém tenantu zákazníka | Jedna aplikace, jeden certifikát, token pro každé ID tenantu zákazníka | **Doporučeno**: jednoduché, auditovatelné, zákazník může přístup odvolat |
| Registrace aplikace vytvořená v každém tenantu zákazníka | Samostatné tajemství pro každého zákazníka | Více tajemství k rotaci |
| Partnerský vztah GDAP (pokud je Integrit CSP partnerem) | Delegované administrátorské role | GDAP je určen spíše pro delegované administrátory než pro bezobslužný monitoring pouze pod aplikací; ponechat pro administrátorskou práci |

**3. Místo sběru:** externí proxy.

**4. Předpoklady:** globální administrátor zákazníka jednou udělí souhlas (consent); prahy (např. „upozornit, pokud zbývají méně než 2 volné licence E3“); proces obnovení u zákazníka (CSP přes Integrit, nebo přímo).

**5. Triggery:** dostupné licence SKU < `{$M365.SKU.MIN.FREE:"SKU"}` (Varování); 0 dostupných, zatímco uživatelé čekají (Průměrná); placené licence nevyužité > 30 dní nad N (Informace, report: úspory); předplatné vyprší/pozastaveno za < 30 dní (Průměrná) / < 7 dní (Vysoká); synchronizace adresáře starší než 3 h (Vysoká); tajemství aplikace vyprší za < 30 dní (Varování); incident Service Health ovlivňující používanou službu (Průměrná, u nespravovaných informativně); globálních administrátorů > 5 nebo < 2 (Varování); selhání tokenu/consentu (Průměrná).

**7. Report:** tabulka licencí (zakoupené/přiřazené/volné/nevyužité s potenciálními úsporami), obnovení, meziměsíční změny, ukazatele hygieny tenantu.

**9. Pracnost:** **32–56 h** (katalog 24–60 h; v pořádku). Nasazení **1–2 h na tenant** (katalog 2–6 h; s multi-tenant aplikací méně).

**10. Poznámka:** vlastní poznámka katalogu, že část toho patří spíše do „správy tenantu“ než do monitoringu, je správná. Report úspor na licencích je nejsilnějším prodejním argumentem.


## 4.15 MON-VOIP · Monitoring telefonní ústředny a VoIP

### Zákaznický pohled (položka katalogu)

| Pole | Obsah |
|---|---|
| ID | `MON-VOIP` |
| Český název | Monitoring telefonní ústředny a VoIP |
| Co monitorujeme | Dostupnost ústředny, SIP trunky a registrace, klíčové linky nebo brány a alarmy. |
| Přínos | Včasné odhalení výpadku telefonie; rozliší problém ústředny, sítě a operátora. |
| Riziko | 🟠 Vysoké. Výpadek nebo kompromitace může zastavit komunikaci nebo způsobit finanční škodu. |
| Předpoklady na straně zákazníka | Známý výrobce, model, verze a role; podporované rozhraní; seznam kritických trunků a funkcí. |
| Reporting | Dostupnost, výpadky registrací a významné události. |
| Omezení | Možnosti závisí na výrobci a stáří; základní stav nepotvrzuje kvalitu každého hovoru. |
| Hranice služby | Monitoring zahrnuje sběr dat, vyhodnocení a upozornění. Odstranění problému, správa, aktualizace a incident response nejsou součástí, pokud nejsou sjednány samostatně. |

### Obchodní pohled

| Pole | Obsah |
|---|---|
| Cílový zákazník | Vlastní ústředna, SIP trunky nebo virtuální ústředna. |
| Obchodní potenciál | Střední, vyšší u kritické nebo starší telefonie (odhad, ověřit na portfoliu zákazníků) |
| Jednotka | ústředna / měsíc, volitelně za trunk |
| Orientační cena | 300–1 000 Kč (odhad) |
| Produktizace (katalog) | 16–50 h na výrobce |
| Nasazení (katalog) | 2–8 h na ústřednu |
| Navazující služby | Správa ústředny, eskalace k operátorovi. |
| Doručení upozornění | Bez správy: určený kontakt zákazníka. Se správou Integrit: servisní proces Integritu (úkol v Planneru). |

### Technický návrh

**1. Rozsah:** dostupnost a zdraví ústředny (CPU/RAM/disk na appliance nebo VM), stav registrace každého SIP trunku, počty registrovaných linek/zařízení (detekce poklesu), stav bran (FXO/FXS/ISDN), aktivní hovory vs. limit licencí/kanálů, alarmy ústředny, vypršení certifikátu/licence a volitelně indikátory telefonních podvodů (neobvyklý objem mezinárodních hovorů).

**2. Mechanismus ve verzi 7.0.31**

| Platforma | Přístup | Oficiální? |
|---|---|---|
| Asterisk / FreePBX | Oficiální *Asterisk by HTTP* (AMI přes HTTP) pro peery/registrace/hovory, v sadě 7.0; agent na hostiteli pro OS | Ano |
| 3CX (v18/v20) | 3CX API / endpointy stavu systému přes položku Script; agent na hostiteli | Komunita → Integrit |
| Yeastar, Grandstream UCM, Panasonic a další | SNMP a/nebo API výrobce; syslog | Podle výrobce |
| Hostovaná/virtuální ústředna (operátor) | Bez interního přístupu: **externí SIP OPTIONS** sondy na SBC/koncový bod trunku, API portálu operátora, pokud existuje | Skript Integritu |
| Obecná SIP kontrola | `ExternalScripts` na proxy (např. sipsak nebo malý SIP OPTIONS klient v Pythonu) vracející kód odpovědi a RTT. Zabbix nemá nativní SIP kontrolu | Vytvoří Integrit |

**3. Místo sběru:** proxy v lokalitě (on-prem ústředna); externí proxy (hostovaná ústředna, koncové body trunků).

**4. Předpoklady:** výrobce, model, verze (katalog to vyžaduje); účet API/AMI pouze pro čtení; seznam kritických trunků, čísel a funkcí (recepce, skupiny vyzvánění); očekávaný počet registrovaných zařízení.

**5. Triggery:** ústředna nedostupná (Vysoká; Katastrofa pro `tier=critical`); trunk neregistrován 2 min (Vysoká); pokles registrovaných linek > 30 % (Vysoká); SIP OPTIONS zvenku selhává (Průměrná); kanály > 90 % limitu (Varování); licence/certifikát vyprší za < 30 dní (Varování); neobvyklý počet mezinárodních hovorů (Vysoká, je-li zapnut doplněk proti podvodům).

**6. Závislosti:** problémy trunků závisí na WAN (MON-NET). Pokud WAN nefunguje, upozornění na trunk se potlačí ve prospěch upozornění na lokalitu, takže požadavek katalogu „rozlišit ústřednu vs. síť vs. operátora“ zajišťuje strom závislostí.

**7. Report:** dostupnost, výpadky registrací, incidenty trunků, špičky využití kapacity hovorů.

**9. Pracnost:** obecná SIP kontrola **8–16 h** jednorázově; **16–50 h na výrobce** (odpovídá katalogu). Nasazení **2–6 h na ústřednu**.

**10. První vydání:** závisí na zákaznické bázi. Nejefektivnějším startem je kontrola SIP OPTIONS (funguje pro libovolného výrobce) plus jeden výrobce s API (3CX nebo FreePBX).


## 4.16 MON-CUSTOM · Monitoring vlastní aplikace nebo integrační úlohy

### Zákaznický pohled (položka katalogu)

| Pole | Obsah |
|---|---|
| ID | `MON-CUSTOM` |
| Český název | Monitoring vlastní aplikace nebo integrační úlohy |
| Co monitorujeme | Běh služby nebo úlohy, očekávaný soubor nebo záznam, chyby v logu, dobu běhu a dostupnost API nebo portu. |
| Přínos | Zachytí tichá selhání dávek, exportů, importů a integrací; jeden přehled nad specifickými procesy. |
| Riziko | 🟡 až 🔴, podle důležitosti procesu. |
| Předpoklady na straně zákazníka | Popsaný očekávaný běh a výsledek, technický signál, časové limity a frekvence. |
| Reporting | Podle důležitosti; u kritických úloh měsíční úspěšnost a incidenty. |
| Omezení | Změna aplikace, logu nebo procesu může vyžadovat změnu kontroly. |
| Hranice služby | Monitoring zahrnuje sběr dat, vyhodnocení a upozornění. Odstranění problému, správa, aktualizace a incident response nejsou součástí, pokud nejsou sjednány samostatně. |

### Obchodní pohled

| Pole | Obsah |
|---|---|
| Cílový zákazník | Vlastní aplikace, dávky a integrace. |
| Obchodní potenciál | Střední, ale s vyšší hodnotou na dodávku (odhad, ověřit na portfoliu zákazníků) |
| Jednotka | kontrola nebo proces / měsíc |
| Orientační cena | 200–1 000 Kč (odhad) |
| Produktizace (katalog) | framework 16–32 h; jednotlivá kontrola 2–16 h |
| Nasazení (katalog) | 1–8 h na kontrolu |
| Navazující služby | Podpora aplikací, vývoj integrací. |
| Doručení upozornění | Bez správy: určený kontakt zákazníka. Se správou Integrit: servisní proces Integritu (úkol v Planneru). |

### Technický návrh

**Povaha:** nejde o jednu šablonu, ale o **framework opakovaně použitelných vzorů kontrol** a standardní „kartu kontroly“, která definuje každou zákaznickou kontrolu ještě před jejím vytvořením. Díky tomu zůstává práce na jednotlivé kontrole malá a každá kontrola je zdokumentovaná.

**Vzory kontrol (framework)**

| Vzor | Mechanismus Zabbixu | Typické použití |
|---|---|---|
| Heartbeat / výsledek úlohy | Úloha (nebo obalový skript Integritu) posílá `status`, `exit_code`, `duration`, `records` přes `zabbix_sender` do trapper položek; `nodata()` odhalí, že úloha neběží | Dávkové exporty/importy, ETL, skripty |
| Aktuálnost souboru | `vfs.file.exists/time/size` a `vfs.dir.count` (aktivní agent) | „Exportní soubor se musí objevit do 06:00 a mít > 0 bajtů“ |
| Vzor v logu | `log[]`, `logrt[]`, `eventlog[]` s regexem, počítání shod | Chybové logy aplikací |
| Služba/proces | `proc.num`, stav služby Windows, jednotka systemd | Aplikační služby |
| Zdraví HTTP/API | HTTP agent s kontrolami stavu/těla/JSON | REST endpointy, health URL |
| Databázový dotaz | Databázové pluginy Agent 2 (MSSQL, PostgreSQL, MySQL, Oracle) nebo ODBC: počty řádků, časová značka posledního zpracování, délka fronty | Integrační tabulky, fronty |
| Port/TCP | `net.tcp.service` | Starší (legacy) služby |
| Složená | Vypočítané položky kombinující výše uvedené (např. „soubor existuje A log neobsahuje ERROR“) | Kontroly na obchodní úrovni |

**Karta kontroly (vyplňuje se před vytvořením, stává se součástí zákaznické dokumentace)**
Název · obchodní účel · vlastník (zákazník a Integrit) · použité signály · plán/časové okno · očekávaný výsledek · prahy · závažnost · kdo dostává upozornění · co má řešitel udělat (runbook) · závislosti · reporting ano/ne · cenová jednotka.

**Triggery:** definované v kartě. Výchozí: zmeškaný běh (Vysoká u kritických procesů), neúspěšný běh (Vysoká), doba běhu > 2× obvyklá (Varování), chybový vzor ≥ N (Průměrná).

**9. Pracnost:** framework (obalové skripty pro Windows/Linux, knihovna šablon, formulář karty kontroly, sekce reportu) **24–40 h** (katalog 16–32 h). Na kontrolu **2–8 h** (katalog 2–16 h vytvoření, 1–8 h nasazení; dohromady konzistentní).

**10. Poznámka:** do této služby směřují požadavky na položky, které ostatní služby nepodporují (např. okrajový zálohovací produkt dříve, než dostane vlastní konektor). Karta kontroly je bránou, která brání tomu, aby se z jednorázové práce stalo neudržovatelné řešení.

# Část 5 · Doplňkové služby (návrhy)

Služby, které **nejsou** v katalogu v1.0/v1.1, navržené pro centrální multi-tenant Zabbix Integritu **7.0.31**. Každá služba je popsána v desetibodové struktuře z `../Part 4, které předchází **0. Položka katalogu** (navržené ID, český název, riziko, jednotka, cena, text pro zákazníka, omezení), aby ji bylo možné převzít rovnou do katalogu. Konektivita, tagování, alerting/Planner a reporting se řídí návrhem platformy v `../Parts 3–4 a zde se znovu nedefinují.

**Jak byla ověřena dostupnost šablon:** proti oficiálnímu repozitáři `zabbix/zabbix`, větev `release/7.0` (poslední commit 14. 10. 2026), nikoli proti integračním stránkám zabbix.com (ty uvádějí požadavky nejnovější větve). Položky označené *(ověřit)* je potřeba ověřit v laboratoři na verzi 7.0.31.

## 5.1 Doporučení na jedné stránce

Přidat **17 služeb** ve třech vlnách. Vlna A přináší nejvíc hodnoty za nejmenší pracnost a zapadá do stávajícího pilotu (servery, zálohování, UPS, DNS). Pro Vlnu A nejsou potřeba žádné nové závazky vůči výrobcům nad rámec těch, které Integrit stejně musí zvolit pro základní katalog.

| Vlna | ID | Služba | Riziko | Jednotka | Cena / měsíc (Kč, odhad) | Produktizace (h) | Proč v této vlně |
|---|---|---|---|---|---|---|---|
| **A** | MON-HW | Hardware serverů (iDRAC/iLO) | 🔴 | fyzický server | 150–300 (100–200 jako doplněk k MON-SRV) | 8–16 | Oficiální šablony; uzavírá mezeru u RAID řadičů, kterou MON-SRV nechává otevřenou |
| **A** | MON-DB | Databáze (MS SQL, MySQL, PostgreSQL) | 🔴 | instance | 300–700 | 28–44 | Oficiální šablony pro agent 2; ERP a účetnictví běží na SQL (limit Express, stáří záloh) |
| **A** | MON-AD | Active Directory / řadiče domény | 🔴 | doména (+ za DC) | 500–1 000 + 150–300/DC | 24–40 | Má ji každý SMB zákazník; replikace, SYSVOL a změny privilegovaných skupin selhávají potichu |
| **A** | MON-MAIL | Tok pošty a zabezpečení poštovní domény | 🟠 | doména (+ poštovní server) | Basic 100–250 · Plus 300–600 · server 300–600 | 48–72 | Využívá kód MON-DNS a aplikaci Graph pro M365; silná hodnota viditelná pro zákazníka |
| **A** | MON-ENV | Prostředí serverovny | 🔴 | senzorová jednotka | 200–400 + hardware | 12–20 | Jednoduché SNMP, čeští výrobci (HW group, Comet, Papouch), tržby z hardwaru |
| **A** | MON-CERT | Interní certifikáty, PKI, tokeny Apple | 🟠 | zákazník (odstupňováno) | 200–600 | 16–24 | Levné; předchází klasickému výpadku „v pondělí přestala fungovat VPN/Wi-Fi/iPhony“ |
| B | MON-IDSEC | Bezpečnost identit (Entra ID) | 🔴 | tenant | 500–1 500 | 32–48 | Nejčastější cesta útoku; nadstavbová úroveň MON-M365, nejprve potřebuje její aplikaci Graph |
| B | MON-CLOUD | Azure (AWS, GCP) | 🟠 | předplatné/účet | 500–1 500 + za prostředek | Azure 16–24 (AWS 12–20) | Oficiální šablony včetně zálohovacích úloh a nákladů; přístupový model přes Lighthouse |
| B | MON-ROLE | Balíčky serverových rolí (soubory, DHCP, DNS, RDS, IIS, tisk) | 🟠 | role/server | 100–300 za roli | 8–16 za balíček | Vytváří z MON-SRV úrovně Standard/Plus |
| B | MON-SECEVT | Základní bezpečnostní události | 🔴 | server | 100–200 | 16–24 | Využívá stávajícího agenta; obchodní tahák NIS2; vstup do spravované bezpečnosti |
| B | MON-EXPOSURE | Externí útočná plocha | 🔴 | veřejná IP | 100–200 (min. 300) | 24–40 | Vystavené RDP/VPN = hlavní vstup ransomwaru; doklad pro NIS2 |
| B | MON-MDM | Soulad správy zařízení (Intune) | 🟠 | tenant + zařízení | 300 + 10–30/zařízení | 24–32 | Soulad pracovních stanic v aktualizacích a šifrování; doplňuje MON-EPS |
| B | SRV-SHUTDOWN | Řízené vypínání při výpadku napájení | 🔴 | prostředí | 200–500 + zřízení | 16–24 | Servisní služba (ne monitoring) nad MON-UPS; vzešlo z návrhu MON-UPS |
| B | MON-LIFECYCLE | Životní cyklus, záruky, konec podpory | 🟡 | zákazník | 300–800 nebo v balíčcích se správou | 24–40 | Převážně report; silný obchodní nástroj Integritu (obnova hardwaru, prodloužení) |
| C | MON-CCTV | Kamery / NVR | 🟠 | rekordér (+ kamery) | 300–600 + 150–300/8 kamer | 16–24 | Oficiální šablona Hikvision; poptávku je třeba potvrdit |
| C | MON-PRINT | Tiskárny / MFP | 🟢 | zařízení | 30–80 | 8–12 | Samostatně malá hodnota; jen v balíčku pro lokalitu nebo s dodávkou spotřebního materiálu |
| C | MON-CONT | Kontejnery / Kubernetes | 🟠 | host / cluster | 200–400 / 1 500–4 000 | Docker 4–8, K8s 24–40 | Pravděpodobně malá poptávka v SMB; projektově, dokud nebudou alespoň 3 zákazníci |

**Celková pracnost** (produktizace, první výrobce/platforma, bez sekcí reportu):
- Vlna A: **≈ 136–216 h**
- Vlna B: **≈ 176–280 h**
- Vlna C: **≈ 64–104 h** (včetně AWS)
- Sekce reportu podle návrhu reportingu (4–12 h každá): **≈ 68–204 h** pro všech 17
- **Všechny doplňkové služby: ≈ 450–800 h**, nad rámec základu platformy a základního katalogu v `Part 6`.

**Zapadnutí do zavádění:** Vlnu A zahájit hned po pilotu (fáze 2 zavádění podle návrhu), protože MON-HW, MON-DB a MON-AD využívají agenta a proxy v lokalitě, které nainstaluje pilot, a MON-MAIL Basic využívá MON-DNS. Vlna B potřebuje multi-tenant aplikaci Graph Integritu (postavenou pro MON-M365) a rozhodnutí o pozicování spravované bezpečnosti.

## 5.2 Navržené balíčky

Zákazníci kupují výsledky, ne 33 položek ceníku. Ceník po jednotlivých službách ponechat interní a prodávat balíčky:

| Balíček | Obsahuje | Poznámka |
|---|---|---|
| **Server Standard / Plus** | MON-SRV (+ MON-ROLE až 3 role, + MON-HW u fyzických serverů) | MON-HW a MON-ROLE jako úrovně, ne samostatné řádky |
| **Zabezpečení domény a pošty** | MON-DNS + MON-MAIL Basic | Jeden produkt na doménu |
| **Tok pošty** | MON-MAIL Plus | Samostatná položka (vyžaduje souhlas s přístupem do schránky) |
| **Microsoft 365 Basic / Identity** | MON-M365 (+ MON-IDSEC) | Stejná aplikace Graph |
| **Endpoint Basic / Plus** | MON-EPS (+ MON-MDM) | Stejný vzor agregace za tenant |
| **Základ lokality** | Brána MON-NET + MON-UPS + MON-ENV (+ MON-PRINT, MON-CCTV) | Přirozeně s proxy v lokalitě a poplatkem za onboarding |
| **Bezpečnostní základ** | MON-SECEVT + MON-EXPOSURE + změny skupin z MON-AD + MON-IDSEC | Prodávat jako podporu NIS2, jasně „nejde o SOC“ |
| **Balíčky se správou** | zahrnují reporting MON-LIFECYCLE a MON-CERT | Odlišení pro zákazníky „se správou Integrit“ |

## 5.3 Průřezové body návrhu

1. **Jeden přístupový model Microsoftu pro vše, co stojí na Graphu** (MON-M365, MON-IDSEC, MON-MAIL Plus, MON-MDM, tokeny Apple v MON-CERT). Doporučení: **dvě multi-tenant aplikace Entra Integritu**, ne jedna: *Integrit Monitoring (read)* pro adresář, audit, reporty a Intune; a *Integrit Mail Probe* s `Mail.Send`/`Mail.ReadWrite` omezenými na testovací schránky pomocí Exchange Online RBAC for Applications. Oddělení drží oprávnění ke schránkám mimo širokou čtecí aplikaci a usnadňuje zákazníkům udělení souhlasu. Přidání oprávnění do aplikace vyžaduje nový souhlas v každém tenantu, proto je potřeba sadu oprávnění čtecí aplikace definovat předem pro **všechny** služby na Graphu.
2. **Azure Lighthouse** pro MON-CLOUD (jeden principál Integritu, zákazník jej může odvolat).
3. **Agregace za tenant, detail na vyžádání** (z návrhu MON-EPS) platí pro MON-MDM, MON-IDSEC a discovery v MON-CLOUD, aby počty hostů, šum i fakturace zůstaly předvídatelné.
4. **Doplňky postavené na agentovi jedou na MON-SRV** (MON-DB, MON-AD, MON-ROLE, MON-SECEVT): žádná nová konektivita, MON-SRV je předpokladem a všechny jejich triggery závisí na dostupnosti z MON-SRV.
5. **Vzor sondy na proxy v lokalitě:** agent 2, který už je v každém obrazu proxy, slouží jako „sondovací host“ pro kontroly interních certifikátů (MON-CERT), kontroly portů a DNS pro AD (MON-AD) a kontroly RTSP kamer (MON-CCTV).
6. **Externí skenovací VM** (MON-EXPOSURE) je oddělená od externích proxy, s publikovanými zdrojovými IP adresami a písemným souhlasem zákazníka.
7. **Hranice v textu pro zákazníka:** každá služba s bezpečnostním zaměřením (MON-IDSEC, MON-SECEVT, MON-EXPOSURE, MON-CCTV) výslovně uvádí, že nejde o SOC/SIEM, penetrační test ani službu pultu centralizované ochrany, protože přesně to by zákazníci jinak předpokládali. MON-ENV uvádí, že nejde o požární signalizaci.
8. **Osobní údaje:** MON-IDSEC (protokoly přihlášení), MON-MAIL Plus (přístup do schránek) a MON-SECEVT (události přihlášení) zpracovávají osobní údaje → musí je uvádět smlouva o zpracování osobních údajů se zákazníky.

## 5.4 Zvážené a nenavržené (pro první vydání)

| Oblast | Proč ne | Alternativa |
|---|---|---|
| Analýza síťového provozu (NetFlow/sFlow/IPFIX, top talkers) | Zabbix není kolektor toků | ntopng nebo ElastiFlow jako samostatný nástroj, bude-li poptávka; provoz rozhraní zůstává v MON-NET |
| Plnohodnotný SIEM / SOC / uchovávání logů pro NIS2 | Jiný produkt, jiné dovednosti a nepřetržitý provoz 24/7 | Wazuh, Microsoft Sentinel nebo Graylog jako budoucí linie spravované bezpečnosti (viz varianty MON-SECEVT) |
| Monitoring výkonu aplikací (tracing, RUM) | Mimo záběr Zabbixu | MON-WEB-FUNC pro syntetické kontroly; nástroje APM na vyžádání |
| Monitoring pracovních stanic agenty | Velký počet hostů, mnoho šumu, malá hodnota na zařízení | MON-MDM (Intune) a MON-EPS na úrovni tenantu |
| Řízení budov / OT (HVAC, Modbus, BACnet) | Specializovaná oblast | MON-CUSTOM na vyžádání (Zabbix umí číst Modbus přes plugin agenta 2 *(ověřit)*) |
| Google Workspace | Zákaznická základna zaměřená na Microsoft | Na vyžádání |
| Wi-Fi AP jako samostatná položka | Už je otevřenou otázkou v revizi katalogu | Rozhodnout tam |
| Stav aktualizací serverů | Už je v MON-SRV podle technického návrhu | Pracovní stanice přes MON-MDM |


## 5.5 Potřebná rozhodnutí

1. **Které vlny převzít do katalogu** (doporučení: Vlnu A hned, Vlnu B po pilotu, Vlnu C na vyžádání).
2. **Počty v zákaznické základně** pro potvrzení výrobců: značky serverového hardwaru, edice SQL / systémy ERP, výrobce senzorů prostředí (standardizovat na jednoho), značky kamer, Azure vs. AWS, rozšíření Intune.
3. **Balíčky** podle kapitoly 2, nebo samostatné položky za službu.
4. **Pozicování spravované bezpečnosti**: zda MON-SECEVT, MON-EXPOSURE a MON-IDSEC prodávat už nyní jako „Bezpečnostní základ“ a jak mimo pracovní dobu řešit bezpečnostní události úrovně Katastrofa.
5. **Model hardwaru pro MON-ENV** (prodej, pronájem v rámci měsíčního poplatku, nebo vlastnictví zákazníka). Doporučení: pronájem.
6. **Doplnění smluv**: souhlas se skenováním (MON-EXPOSURE), sonda do schránky a zpracování dat (MON-MAIL Plus, MON-IDSEC), formulace „nejde o požární signalizaci / nejde o SOC“.


## 5.6 Podrobnosti služeb

Každý návrh níže začíná položkou katalogu (zákaznický a obchodní pohled), po níž následuje stejná technická struktura jako v Části 4.


### 5.6.1 MON-HW · Hardware serverů (out-of-band)

**0. Položka katalogu**

| Pole | Návrh |
|---|---|
| Český název | Monitoring hardwaru serveru (iDRAC/iLO) |
| Riziko | 🔴 Kritické (selhání disku, řadiče nebo zdroje → ztráta dat nebo výpadek) |
| Jednotka | fyzický server / měsíc |
| Cena | 150–300 Kč, nebo 100–200 Kč jako doplněk k MON-SRV na stejném serveru |
| Text pro zákazníka | Hlídáme hardware serveru přes jeho management kontrolér (iDRAC, iLO, XCC, IPMI), nezávisle na operačním systému: disky a RAID, napájecí zdroje, ventilátory, teploty, chyby pamětí a procesorů, baterii řadiče. Selhávající komponentu vidíme i tehdy, když operační systém neběží nebo ji nehlásí. |
| Omezení | Vyžaduje připojený a licencovaný management port. Nezahrnuje reklamace v záruce ani výměnu dílů. |

**1. Rozsah:** dostupnost BMC; souhrnný stav zdraví systému; fyzické disky (stav, předpověď selhání, příznak SMART z řadiče), virtuální disky / RAID (degradovaný, rebuild, selhaný), RAID řadič a jeho baterie/cache; napájecí zdroje (stav, ztráta redundance, vstupní napětí); ventilátory; teplotní čidla (vstup vzduchu/CPU); paměti (míra opravitelných chyb ECC, selhání DIMM); stav CPU; stav linky síťových karet; změny verze firmwaru/BIOSu; otevření skříně; kritické záznamy SEL (System Event Log); restarty hosta zaznamenané BMC. Jde o položku „hardwarové RAID řadiče… patří do OOB služby“, na kterou odkazuje Část 4 (MON-SRV, řádek SMART).

**2. Mechanismus na 7.0.31**

| Platforma | Jak | Oficiální v release/7.0? |
|---|---|---|
| Dell iDRAC 7/8/9 | *Dell iDRAC by SNMP* (obecná, všechny modely) — doporučená výchozí. Existují i modelově specifické šablony Redfish *DELL PowerEdge R660/R720/R740/R750/R820/R840 by HTTP*, ty jsou ale vázané na modely | Ano |
| HPE iLO 4/5/6 | *HPE iLO by HTTP* (Redfish, skriptové položky, bez externích skriptů); *HP iLO by SNMP* pro starší iLO | Ano |
| Lenovo XClarity (XCC) | Bez oficiální šablony. Šablona Integritu nad Redfishem (standardní schémata DMTF `/redfish/v1/Systems`, `/Chassis/*/Thermal`, `/Power`, `/Storage`) vytvořená úpravou šablony HPE Redfish | Vytváří Integrit |
| Supermicro | *Supermicro Aten by SNMP* | Ano |
| IBM/Lenovo IMM (starší) | *IBM IMM by SNMP* | Ano |
| Fujitsu iRMC, ostatní | Obecný Redfish (viz výše) nebo *Chassis by IPMI* | Obecná |
| Jakékoli BMC bez SNMP/Redfish | *Chassis by IPMI* (IPMI pollery serveru přes proxy v lokalitě) | Ano, omezená hloubka |
| Cisco UCS | *Cisco UCS by SNMP*, *Cisco UCS Manager by SNMP* | Ano (v SMB vzácné) |
| Okamžité události | SNMP trapy z iDRAC/iLO do snmptrapd na proxy v lokalitě (selhání disku, ztráta zdroje) — zdrojem pravdy zůstává dotazování (polling) | Mapování trapů Integritu |

**Doporučený standard:** Redfish (HTTPS) přednostně tam, kde existuje oficiální šablona (HPE), SNMPv3 pro Dell (obecná šablona pokrývá všechny generace), IPMI jen jako poslední možnost. IPMI 2.0 má známou slabinu autentizace (únik hashe v RAKP), proto musí zůstat v management VLAN.

**3. Místo sběru:** proxy v lokalitě (BMC jsou v LAN / management VLAN). Volitelně trapy na stejnou proxy.

**4. Předpoklady na straně zákazníka:** management port zapojený a v síti, na kterou proxy dosáhne (často zapojený není; ověřit při onboardingu); přiměřeně aktuální firmware BMC; uživatel BMC jen pro čtení (iDRAC „Read Only“, iLO pouze oprávnění „Login“) nebo uživatel SNMPv3; Dell: pro stav zdraví přes SNMP/Redfish stačí iDRAC Express *(ověřit pro jednotlivé generace)*; HPE: pro stav zdraví přes Redfish stačí iLO Standard.

**5. Výchozí triggery**

| Trigger | Závažnost | Výchozí hodnota |
|---|---|---|
| Virtuální disk / RAID degradovaný nebo selhaný | Katastrofa (selhaný) / Vysoká (degradovaný) | stav ≠ OK |
| Selhání fyzického disku | Vysoká | – |
| Předpověď selhání fyzického disku / příznak SMART | Průměrná | – |
| RAID řadič nebo jeho baterie není v optimálním stavu | Průměrná | – |
| Selhání zdroje / ztráta redundance | Vysoká | – |
| Selhání ventilátoru | Průměrná | – |
| Teplotní čidlo varování / kritický stav | Průměrná / Vysoká | Vlastní prahy BMC (definované výrobcem, ne makra Integritu) |
| Selhání paměťového modulu DIMM / vysoká míra opravitelných chyb ECC | Vysoká / Varování | – |
| BMC nedostupné | Varování (interní pro Integrit) | 15 min; neznamená, že server neběží |
| Změna firmwaru / BIOSu | Informace | jen do reportu |
| Otevření skříně | Průměrná | kde je podporováno |

**6. Závislosti a omezení falešných poplachů:** hosty BMC závisí na bráně lokality. Host operačního systému **nenastavovat** jako závislý na BMC (selhávají nezávisle). Pokud MON-VIRT už čte hardwarová čidla ESXi (CIM), na hostech s MON-HW tam duplicitní hardwarové položky vypnout, jinak tentýž selhaný zdroj vyvolá dva problémy. Upgrady firmwaru → okno údržby, protože se BMC restartují.

**7. Report:** hardwarové incidenty po serverech, výměny komponent (triggery „has been replaced“ pro disky a zdroje v oficiálních šablonách), trend teploty (vstup vzduchu), tabulka verzí firmwaru (podklad pro MON-LIFECYCLE).

**8. Varianty výrobců pro první vydání:** Dell (iDRAC SNMP) + HPE (iLO Redfish) — obojí oficiální; Lenovo přes šablonu Redfish od Integritu, jakmile ji bude potřebovat první zákazník. Nejprve spočítat zákaznickou základnu podle výrobců.

**9. Pracnost:** produktizace **8–16 h** pro Dell + HPE (oficiální šablony, obalová šablona Integritu, mapování trapů), **+16–24 h** pro obecnou šablonu Redfish (Lenovo/Fujitsu). Nasazení **0,25–0,5 h na server**, pokud je BMC v síti; **+1–2 h**, když je potřeba management port zapojit nebo nakonfigurovat (účtovat jako práci).

**10. Rizika / otevřené body:** BMC bývají často neaktualizovaná a vystavená; monitoring nesmí být důvodem k jejich zpřístupnění šířeji než pro proxy. Rozhodnout, zda je MON-HW samostatná položka, nebo varianta MON-SRV pro „fyzický server“ (doporučení: **varianta/doplněk**, protože zákazníci uvažují „server“, ne „BMC“).


### 5.6.2 MON-ENV · Prostředí serverovny

**0. Položka katalogu**

| Pole | Návrh |
|---|---|
| Český název | Monitoring prostředí serverovny (teplota, vlhkost, zaplavení) |
| Riziko | 🔴 Kritické (výpadek klimatizace nebo únik vody zničí hardware během několika hodin) |
| Jednotka | senzorová jednotka (základní jednotka až se 4 čidly) / měsíc; hardware prodaný, pronajatý nebo zahrnutý v ceně |
| Cena | 200–400 Kč za základní jednotku; hardware čidel zvlášť (jednorázově 3 000–12 000 Kč na lokalitu podle výrobce a čidel) |
| Text pro zákazníka | Hlídáme teplotu, vlhkost a tam, kde jsou instalována, i čidla zaplavení, dveří a kouře ve vaší serverovně nebo racku a upozorníme na selhávající klimatizaci dřív, než se zařízení přehřeje. |
| Omezení | Nejde o certifikovaný systém požární signalizace ani zabezpečovací systém (EPS/PZTS) a takový systém nenahrazuje. |

**1. Rozsah:** teplota (vstup do racku, místnost), rychlost nárůstu teploty (indikátor selhání klimatizace), vlhkost (a rosný bod, pokud jej zařízení poskytuje), zaplavení (pod klimatizační jednotkou / zdvojenou podlahou), dveřní kontakt (rack nebo místnost), kouř (informativně, nejde o požární ochranu), přítomnost síťového napětí (má-li jednotka bezpotenciálový kontakt), baterie čidla a „čidlo neaktualizuje data“ u bezdrátových čidel, dostupnost samotné senzorové jednotky.

**2. Mechanismus na 7.0.31**

| Rodina zařízení | Jak | Oficiální v release/7.0? |
|---|---|---|
| **HW group** (český výrobce: HWg-STE, STE2, Poseidon2, HWg-WLD) | SNMP (HWg MIB) — šablona Integritu s LLD nad čidly; HW group publikuje vlastní šablony pro Zabbix *(ověřit pro 7.0)* | Vytváří/upravuje Integrit |
| **Comet System** (český výrobce: Web Sensor P8541/P8552 apod.) | SNMP nebo HTTP XML/JSON | Vytváří Integrit |
| **Papouch** (český výrobce: TME, Papago) | SNMP / HTTP XML | Vytváří Integrit |
| **Aranet** (bezdrátová čidla LoRa se základnovou stanicí PRO) | *Aranet Cloud by HTTP* | Ano |
| APC NetBotz / environmentální čidlo UPS (AP9335T apod.) | SNMP (PowerNet MIB, OID `iem*`/`uio*`); pro čidla UPS rozšířit obalovou šablonu MON-UPS | Vytváří Integrit |
| AKCP sensorProbe | SNMP | Komunitní → Integrit |
| Záložní řešení | Teplota vstupu vzduchu z MON-HW (BMC) a teplotní čidla switchů/UPS — zdarma, ale měří zařízení, ne místnost | Stávající šablony |

**Doporučení:** standardizovat na **jednoho výrobce drátových čidel** (HW group nebo Comet: oba čeští, SNMP, varianty s PoE, lokální podpora, dobrá cena) plus Aranet pro lokality, kde je kabeláž nepraktická. Jeden výrobce = jedna šablona = jedna zásoba náhradních čidel.

**3. Místo sběru:** proxy v lokalitě (SNMP), externí proxy pro Aranet Cloud.

**4. Předpoklady na straně zákazníka:** místo pro montáž čidel (vstup do racku v polovině výšky, u výdechu klimatizace, pod klimatizací pro zaplavení), port LAN/PoE, běžný teplotní profil místnosti, servisní kontakt na klimatizaci (upozornění jsou k ničemu, pokud klimatizaci v noci nikdo neopraví).

**5. Výchozí triggery** (makra za lokalitu; výchozí hodnoty vycházejí z doporučeného rozsahu ASHRAE A1, 18–27 °C na vstupu)

| Trigger | Závažnost | Výchozí hodnota |
|---|---|---|
| Vysoká teplota | Průměrná | > `{$ENV.TEMP.WARN}` = 27 °C po dobu 10 min |
| Kritická teplota | Vysoká | > `{$ENV.TEMP.CRIT}` = 32 °C po dobu 5 min |
| Extrémní teplota | Katastrofa | > 35 °C |
| Rychlý nárůst (selhání klimatizace) | Vysoká | `+3 °C` během 15 min (výraz typu `change`/`trendavg` nad `max(15m)-min(15m)`) |
| Vlhkost mimo rozsah | Varování | < 20 % nebo > 70 % RH po dobu 30 min |
| Zaplavení | Katastrofa | jakékoli |
| Otevřené dveře | Informace / Varování mimo pracovní dobu | otevřeno > 15 min |
| Detekován kouř | Katastrofa | pouze informativně, viz omezení |
| Čidlo/jednotka neposílá data | Průměrná | `nodata(15m)` |
| Slabá baterie čidla (bezdrátové) | Varování | hodnota výrobce |

**6. Závislosti:** jednotka závisí na bráně lokality (nestriktní `nodata` spolu s bufferováním na proxy pokryje výpadky WAN). Korelovat „nárůst teploty“ s „UPS na baterii“ (klimatizace obvykle není na UPS → při výpadku napájení se místnost ohřívá; je to očekávané, ale přesto jde o upozornění).

**7. Report:** minimální/průměrná/maximální teplota a vlhkost za měsíc, doba nad prahem, události zaplavení a dveří, doporučení (např. „vstup odpoledne pravidelně nad 27 °C → kapacita klimatizace“).

**8. Varianty výrobců:** HW group nebo Comet (drátové, SNMP) + Aranet (bezdrátové, oficiální šablona). Rozhodnout o jednom primárním.

**9. Pracnost:** produktizace **8–16 h** na výrobce (jednoduché SNMP, malý model čidel) + **4 h** obalová šablona pro Aranet. Nasazení **1–2 h na lokalitu** včetně fyzické instalace (účtováno jako práce); samotná konfigurace **0,25 h**.

**10. Rizika / otevřené body:** **obchodní model hardwaru** (prodej, pronájem v rámci měsíčního poplatku, nebo vlastnictví zákazníka) — pronájem z toho dělá „lepivou“ opakovanou službu a je doporučenou variantou. Hranice „nejde o požární signalizaci“ musí být v textu pro zákazníka i ve smlouvě.


### 5.6.3 MON-ROLE · Balíčky serverových rolí

Doplněk k MON-SRV: kontroly specifické pro roli nad základním monitoringem operačního systému. Prodává se za roli a server, takže MON-SRV zůstává čistým a levným základem. Návrh MON-SRV už uvádí sady regulárních výrazů pro „role“ v event logu; tato služba je formalizuje jako zpoplatněné balíčky.

**0. Položka katalogu**

| Pole | Návrh |
|---|---|
| Český název | Rozšířený monitoring role serveru |
| Riziko | 🟠 Vysoké (selhání role zastaví celou funkci: přidělování adres, soubory, práci na terminálu) |
| Jednotka | role / server / měsíc (předpokladem je MON-SRV) |
| Cena | 100–300 Kč za roli |
| Text pro zákazníka | Nad rámec operačního systému hlídáme konkrétní roli, kterou server poskytuje: sdílení souborů, DHCP, DNS, tisk, terminálové služby (RDS) nebo webové služby. |
| Omezení | Kontroluje stav a kapacitu role, nikoli správnost dat nebo oprávnění. |

**1. Rozsah podle balíčku**

| Balíček | Kontroly |
|---|---|
| **DHCP** (Windows) | Služba; využití každého scope (klasická příčina výpadků); stav failover vztahu; události konfliktů a odmítnutí |
| **DNS server** (Windows/BIND) | Služba; test lokálního překladu (interní a externí jméno); dostupnost forwarderů; chyby přenosu zón / zón integrovaných do AD v logu DNS Server; selhání rekurzivních dotazů (výkonové čítače) |
| **Souborový server** | Sdílené složky online; prahy kvót FSRM; stav DFS Namespace a DFS-R a backlog; stínové kopie (Volume Shadow Copy): stáří nejnovějšího snímku a jejich počet (náhlý pokles je indikátorem ransomwaru); počty otevřených souborů a relací (trend) |
| **Tiskový server** | Služba Spooler; fronty v chybě; úlohy zaseknuté déle než N min |
| **RDS** | Služby Session Host, Connection Broker, Gateway a Licensing; **dostupnost RDS CAL a licenční lhůta (grace period)** (vypršení lhůty zastaví přihlašování); počet relací vůči kapacitě; certifikát Gateway (s MON-CERT) |
| **IIS / web** | Oficiální *IIS by Zabbix agent active*: stav aplikačních poolů, stav webů, fronty požadavků, míra chyb 5xx |
| **Linuxový webový stack** | Oficiální šablony agenta *Nginx*, *Apache*, *PHP-FPM*; *Systemd by Zabbix agent 2* pro jednotky |
| **Exchange on-prem** | → přesunuto do MON-MAIL |
| **Hostitel Hyper-V** | → zůstává v MON-VIRT |
| **SQL** | → MON-DB |
| **Řadič domény** | → MON-AD |

**2. Mechanismus na 7.0.31:** IIS, Nginx, Apache, PHP-FPM, systemd: oficiální šablony. DHCP, DNS server, souborový server, tisk, RDS: **šablony Integritu** na agentovi 2 — výkonové čítače (`perf_counter_en[]`), `service.info[]`, `eventlog[]` a PowerShell UserParameters s LLD (`Get-DhcpServerv4ScopeStatistics`, `Get-DhcpServerv4Failover`, `Get-FsrmQuota`, `Get-DfsrBacklog`, `Get-CimInstance Win32_ShadowCopy`, `Get-Printer`/`Get-PrintJob`, licencování RDS přes `Win32_TSLicenseKeyPack` a licenční lhůta přes `Win32_TerminalServiceSetting`). Pomalé příkazy (backlog DFS-R) běží každých 15–60 min s nastaveným `Timeout` pro konkrétní položku (7.0 podporuje timeouty na úrovni položky).

**3. Místo sběru:** aktivní agent → proxy v lokalitě (stejně jako MON-SRV).

**4. Předpoklady:** nasazený MON-SRV; seznam rolí na jednotlivých serverech; prahy pro jednotlivé role (sledované DHCP scope, sdílené složky v rozsahu, typ a počet RDS CAL).

**5. Výchozí triggery (výběr)**

| Trigger | Závažnost | Výchozí hodnota |
|---|---|---|
| Využití DHCP scope | Průměrná / Vysoká | > 85 % / > 95 % |
| DHCP failover není v normálním stavu | Vysoká | stav ≠ Normal |
| Selhává lokální překlad DNS | Vysoká | 2 neúspěchy po sobě |
| Nejnovější stínová kopie starší než 26 h nebo pokles počtu o více než 50 % | Průměrná / Vysoká | – |
| Kvóta FSRM | Varování / Průměrná | 85 % / 95 % |
| Backlog DFS-R | Průměrná | > 1 000 souborů po dobu 1 h |
| Tisková fronta v chybě / zaseknutá úloha | Varování | > 15 min |
| Aktivní licenční lhůta RDS / vyčerpané CAL | Vysoká | zbývá ≤ 30 dní lhůty |
| Zastavená služba role RDS | Vysoká | – |
| Zastavený aplikační pool IIS | Vysoká | oficiální šablona |

**6. Závislosti:** vše závisí na triggeru dostupnosti hosta z MON-SRV. Triggery VSS potlačit během zálohovacích oken, pokud zálohovací produkt snímky odstraňuje.

**7. Report:** po rolích: kapacita (scope, kvóty, relace), incidenty, významné události.

**8. První vydání:** Souborový server + DHCP + RDS (nejběžnější role v SMB a zároveň ty s nejvíce „tichými“ selháními). IIS/linuxový web na oficiálních šablonách, kdykoli bude potřeba.

**9. Pracnost:** produktizace **8–16 h na balíček** (balíčky pro Windows), **2–4 h** na obalovou šablonu nad oficiální šablonou. Nasazení **0,25–0,5 h na roli**.

**10. Otevřené:** zda budou balíčky rolí na faktuře samostatnými řádky, nebo součástí úrovně „MON-SRV Plus“. Doporučení: interně ceník po rolích, zákazníkům ale prodávat **MON-SRV Standard / Plus** (Plus = až 3 balíčky rolí).


### 5.6.4 SRV-SHUTDOWN · Řízené vypínání při výpadku napájení

**Servisní služba, nikoli monitoring** (stejná rodina jako SRV-RESTORE). Vzešla jako otevřený bod v Části 4 (MON-UPS §10).

**0. Položka katalogu**

| Pole | Návrh |
|---|---|
| Český název | Řízené vypnutí při výpadku napájení |
| Riziko | 🔴 Kritické (nekontrolovaná ztráta napájení poškodí VM, databáze, svazky NAS) |
| Jednotka | prostředí chráněné UPS / měsíc, plus jednorázové zřízení |
| Cena | zřízení individuálně (4–16 h práce); 200–500 Kč/měsíc včetně ročního testu |
| Text pro zákazníka | Když UPS běží na baterii a výpadek trvá, servery, virtuální stroje a úložiště se vypnou ve správném pořadí dřív, než se baterie vybije, a tento scénář jednou ročně ověříme. |
| Omezení | Závisí na stavu baterií a na napájecí infrastruktuře zákazníka; test vyžaduje plánované okno. |

**1. Rozsah:** návrh pořadí vypínání (VM → hostitelé → úložiště → síť), konfigurace vypínacího agenta, roční řízený test se zprávou a monitoring toho, že vypínací agenti sami běží a jsou nakonfigurovaní.

**2. Mechanismus:** vypnutí provádějí nástroje výrobců, **ne Zabbix**: APC PowerChute Network Shutdown, Eaton IPM / IPP, UPS klient Synology/QNAP, NUT pro Linux a integrace těchto nástrojů do VMware/Hyper-V. Zabbix monitoruje: běh služby vypínacího agenta (`service.info`), jeho spojení se síťovou kartou UPS (log), zbývající dobu běhu UPS vůči nastavenému prahu pro vypnutí (MON-UPS). Vzdálené příkazy Zabbixu se pro vypínání záměrně **nepoužívají** (proxy může být na stejné UPS a WAN při výpadku obvykle nefunguje).

**3–4. Sběr / předpoklady:** UPS se síťovou kartou (MON-UPS), administrátorský přístup k hypervisorům a úložištím, dohodnuté pořadí vypínání, okno pro test.

**5. Triggery:** vypínací agent zastaven (Vysoká); agent ztratil spojení s UPS (Vysoká); doba běhu UPS < práh pro vypnutí + bezpečnostní rezerva (Průměrná); roční test po termínu (Varování, z makra s datem).

**7. Report:** zpráva z ročního testu (časy jednotlivých kroků, zjištěné problémy).

**9. Pracnost:** produktizace **16–24 h** (postupy pro APC a Eaton + vSphere/Hyper-V, testovací protokol); na zákazníka **4–16 h** zřízení.

**10. Otevřené:** hodí se pro zákazníky, kteří už kupují MON-UPS; velmi nízká konkurence a vysoká vnímaná hodnota po prvním výpadku.


### 5.6.5 MON-LIFECYCLE · Životní cyklus, záruky a konec podpory

Převážně **report** s několika upozorněními založenými na datech. Doporučeno spíše jako součást balíčků se správou než jako samostatná položka.

**0. Položka katalogu**

| Pole | Návrh |
|---|---|
| Český název | Přehled životního cyklu (záruky, podpora výrobce, licence) |
| Riziko | 🟡 Střední (nepodporované systémy nedostávají bezpečnostní opravy; prošlá záruka znamená pomalou a drahou opravu) |
| Jednotka | zákazník / měsíc (odstupňováno podle počtu aktiv) |
| Cena | 300–800 Kč za zákazníka, nebo zahrnuto v balíčcích se správou |
| Text pro zákazníka | Každý měsíc uvidíte, u kterých serverů, zařízení a systémů se blíží konec záruky nebo konec podpory výrobce a která předplatná a certifikáty brzy vyprší, s dostatečným předstihem pro plánování rozpočtu. |
| Omezení | Data pocházejí z údajů výrobců a ze smluv; tam, kde je výrobci nezveřejňují, Integrit nemůže zaručit jejich přesnost. |

**1. Rozsah:** konec hardwarové záruky (servery, NAS, firewally, switche); konec podpory operačních systémů a produktů (např. prodloužená podpora Windows Server 2016 končí 12. 1. 2027; SQL Server 2016 skončil 14. 7. 2026; Exchange 2016/2019 skončil 14. 10. 2025); stáří firmwaru vůči nejnovější verzi; obnovy předplatných a licencí (bezpečnostní předplatná firewallů, licence zálohování, obnovy M365 z MON-M365); stáří baterií (MON-UPS).

**2. Mechanismus na 7.0.31:** údaje o verzích už sbírají jiné služby (verze OS z agenta, firmware ze SNMP/Redfishe, verze SQL z MON-DB). Integrit doplňuje: **tabulku životního cyklu** (produkt/verze → datum konce podpory) spravovanou v Gitu a importovanou jako globální makra nebo jako číselník v generátoru reportů; hardwarovou záruku z **Dell TechDirect warranty API** (vyžaduje registraci Integritu), **Lenovo warranty API**, u HPE ruční zadání (bez jednoduchého veřejného API) *(ověřit)*; pole inventáře hosta (`contract_expiry`, `warranty_expiry`) vyplňovaná inventarizačním nástrojem; vypočítávané položky, které z makra s datem udělají „zbývající dny“.

**3. Místo sběru:** centrálně (generátor reportů + server).

**5. Triggery:** konec podpory OS/produktu za < 180 dní (Varování) / již uplynul (Průměrná); záruka končí za < 60 dní (Informace, report); bezpečnostní předplatné firewallu vyprší za < 30 dní (Průměrná).

**7. Report:** jedna tabulka životního cyklu na zákazníka, seřazená podle data, s výhledem rozpočtu na 12 měsíců. Pro Integrit je to silný **obchodní nástroj** (obnova hardwaru, prodloužení licencí).

**9. Pracnost:** **24–40 h** (tabulka životního cyklu, konektory na API záruk, sekce reportu). Na zákazníka **0,5–1 h** (počáteční data inventáře).

**10. Otevřené:** kdo bude tabulku životního cyklu udržovat (návrh: jeden vlastník v Integritu, čtvrtletní revize).


### 5.6.6 MON-DB · Databáze

**0. Položka katalogu**

| Pole | Návrh |
|---|---|
| Český název | Monitoring databází (MS SQL, MySQL/MariaDB, PostgreSQL) |
| Riziko | 🔴 Kritické (zastaví se ERP, účetnictví a podnikové aplikace; neúspěšné zálohy databází znamenají ztrátu dat) |
| Jednotka | databázová instance / měsíc |
| Cena | 300–700 Kč za instanci (MS SQL Express na jediném aplikačním serveru: spodní hranice) |
| Text pro zákazníka | Hlídáme vaše databázové servery: dostupnost, stav databází, volné místo a růst, zálohy databází a jejich stáří, neúspěšné úlohy údržby, blokování a výkon. Typicky pro účetní a ERP systémy (Pohoda, Money, Helios, ABRA) a podnikové aplikace. |
| Omezení | Neladí dotazy, nekontroluje správnost dat a nenahrazuje podporu aplikace. |

**1. Rozsah:** dostupnost instance a verze; stav databáze (online / suspect / recovery pending / offline); velikost datových a logových souborů, volné místo, růst a limity autogrowth; využití transakčního logu; **stáří poslední plné / rozdílové / logové zálohy pro každou databázi** (nezávislá kontrola nad rámec MON-BKP — zachytí databáze, které nikdo nezařadil do zálohy); selhání úloh SQL Agenta (plány údržby, úlohy indexů, úlohy ERP); blokující relace a deadlocky; neúspěšná přihlášení (indikátor útoku hrubou silou); buffer cache / page life expectancy (trend); počet spojení vůči maximu; stav replikace / Always On AG; **limit velikosti SQL Server Express** (10 GB na databázi; 50 GB od SQL Server 2025 Express) — velmi časté tiché selhání v SMB; edice a úroveň CU (podklad pro MON-LIFECYCLE).

**2. Mechanismus na 7.0.31**

| Databázový stroj | Jak | Oficiální v release/7.0? |
|---|---|---|
| Microsoft SQL Server 2017/2019/2022 | ***MSSQL by Zabbix agent 2*** (načítaný plugin MSSQL ≥ 7.0.10, samostatný balíček / funkce MSI): dostupnost, výkonové čítače, discovery databází a jejich velikosti, **poslední záloha**, **stav úloh SQL Agenta**, AG/mirroring | Ano |
| MS SQL, bez agenta | *MSSQL by ODBC* z proxy v lokalitě (vyžaduje unixODBC + ovladač Microsoft ODBC v obrazu proxy) | Ano |
| MySQL / MariaDB | *MySQL by Zabbix agent 2* (i v aktivní variantě) | Ano |
| PostgreSQL | *PostgreSQL by Zabbix agent 2* (zpoždění replikace, bloat, stáří xid, deadlocky) | Ano |
| Oracle | *Oracle by Zabbix agent 2* / *by ODBC* | Ano (v SMB vzácné) |
| MongoDB, Redis | oficiální šablony pro agent 2 | Ano (na vyžádání) |
| Firebird (starší ABRA, některé české aplikace) | Bez šablony; `UserParameter` s dotazy přes `isql` | Vytváří Integrit, na vyžádání |
| Limit velikosti Express, pravidla pokrytí zálohami | Obalová šablona Integritu: vypočítávaná položka `DB size / {$MSSQL.EXPRESS.LIMIT}` při edici = Express; trigger „databáze bez zálohy“ pro každou databázi s `{$DB.BACKUP.MAXAGE:"dbname"}` | Vytváří Integrit (malý rozsah) |

**Doporučení:** **agent 2 s pluginy** na databázovém serveru (server už má agenta 2 z MON-SRV, takže nevzniká nová síťová cesta); ODBC jen tam, kde zákazník pluginy odmítne.

**3. Místo sběru:** aktivní agent → proxy v lokalitě; cloudové databáze (Azure SQL, RDS) patří do MON-CLOUD.

**4. Předpoklady na straně zákazníka:** monitorovací login s minimálními právy (MS SQL 2022: `VIEW SERVER PERFORMANCE STATE`, `VIEW ANY DEFINITION`, čtení v `msdb`; starší verze: `VIEW SERVER STATE`); MySQL/PostgreSQL: monitorovací role jen pro čtení podle README šablony; seznam databází v rozsahu a očekávání ohledně jejich záloh (plná denně? log každou hodinu?); kontakt na vlastníka / dodavatele aplikace (upozornění často jdou dodavateli ERP, ne IT).

**5. Výchozí triggery**

| Trigger | Závažnost | Výchozí hodnota |
|---|---|---|
| Instance nedostupná / služba zastavena | Katastrofa pro `tier=critical`, jinak Vysoká | – |
| Databáze není ONLINE | Vysoká | – |
| Poslední plná záloha je příliš stará | Vysoká | > `{$DB.BACKUP.FULL.MAXAGE}` = 26 h |
| Poslední záloha logu je příliš stará (model obnovy FULL) | Průměrná | > 2 h |
| Databáze v modelu obnovy FULL bez jakékoli zálohy logu | Průměrná | log roste bez omezení |
| Databáze edice Express blízko limitu | Průměrná / Vysoká | > 80 % / > 95 % limitu |
| Datový/logový soubor nemůže růst (volné místo na disku < další autogrowth nebo dosažena maximální velikost) | Vysoká | – |
| Využité místo v logu | Varování | > 80 % po dobu 30 min |
| Selhání úlohy SQL Agenta | Průměrná | výsledek posledního běhu = failed (pro každou nalezenou úlohu, filtr přes `{$MSSQL.JOB.MATCHES}`) |
| Blokování > N s / deadlocky | Varování | > 60 s / trvale > 0 za minutu |
| Nárazové neúspěšné přihlášení | Varování | > 20 / 5 min (bezpečnostní signál) |
| AG/replika není v pořádku, zpoždění replikace | Vysoká / Průměrná | výchozí hodnoty šablony |
| Změna verze | Informace | report |

**6. Závislosti / falešné poplachy:** závisí na hostu (MON-SRV). Triggery stáří záloh musí respektovat plán (víkendy, databáze zálohované jen měsíčně) pomocí kontextů maker pro jednotlivé databáze. Okna údržby indexů způsobují blokování → údržba nebo časové podmínky v triggerech.

**7. Report:** po instancích: dostupnost, velikosti databází a předpověď růstu (s rezervou do limitu Express), tabulka souladu záloh po databázích, neúspěšné úlohy, incidenty.

**8. První vydání:** nejprve MS SQL (Windows, včetně Express) — právě na něm běží ERP a účetnictví českých SMB. Jako druhé MySQL/MariaDB (webhosting, WordPress). PostgreSQL na vyžádání.

**9. Pracnost:** produktizace **16–24 h** pro MS SQL (oficiální šablona + obalová šablona + logika pro Express a pravidla záloh), **6–10 h** pro každou z obalových šablon MySQL a PostgreSQL. Nasazení **0,5–1 h na instanci** (login, plugin, makra, rozsah databází).

**10. Rizika / otevřené:** plugin MSSQL je samostatná binárka, která musí držet krok s upgrady agenta; plugin se připojuje SQL loginem, jehož heslo je uložené v tajném makru Zabbixu (nebo ve Vaultu, viz návrh platformy). Někteří dodavatelé ERP zakazují na své SQL instanci loginy třetích stran — ověřit ve smlouvách.

### 5.6.7 MON-AD · Active Directory a řadiče domény

**0. Položka katalogu**

| Pole | Návrh |
|---|---|
| Český název | Monitoring Active Directory a doménových řadičů |
| Riziko | 🔴 Kritické (na AD závisí přihlášení, přístup k souborům, ověřování Wi-Fi/VPN i DNS) |
| Jednotka | doména / měsíc (zahrnuje 2 DC), + za každý další DC |
| Cena | 500–1 000 Kč za doménu; +150–300 Kč za každý další DC. Předpokladem je MON-SRV na každém DC |
| Text pro zákazníka | Hlídáme zdraví vaší domény: služby doménových řadičů, replikaci mezi nimi, synchronizaci času, DNS pro doménu, SYSVOL, zálohy AD a změny privilegovaných skupin, jako je Domain Admins. |
| Omezení | Nejde o audit identit ani o SIEM. Nepokrývá Entra ID (viz MON-IDSEC) ani správu uživatelů. |

**1. Rozsah:** základní služby DC (NTDS, Netlogon, KDC, DNS, DFSR, W32Time, ADWS); dostupnost portů LDAP/LDAPS a Kerberos z proxy v lokalitě; replikace AD (poslední úspěch, počet po sobě jdoucích selhání pro každého partnera); existence sdílené složky SYSVOL a normální stav DFS-R SYSVOL; časový posun vůči PDC emulátoru; přeložitelnost DNS SRV záznamů domény (`_ldap._tcp.dc._msdcs.<domain>`); dostupnost držitelů rolí FSMO; **stáří zálohy AD** (událost Directory Service 2089 / `repadmin /showbackup`) vůči tombstone lifetime; **změna členství v privilegovaných skupinách** (Domain Admins, Enterprise Admins, Schema Admins, Administrators, Account Operators, Backup Operators); stáří hesla `krbtgt`; počty pro report: zamčené účty, zakázané/neaktivní účty, administrátorské účty s „heslo nikdy nevyprší“; souhrn DCdiag (denně); služba serveru Entra Connect (ADSync), pokud existuje (samotné stáří synchronizace je v MON-M365).

**2. Mechanismus na 7.0.31:** v release/7.0 **neexistuje oficiální šablona pro AD**. Šablona Integritu nad Windows agentem 2 (nad *Windows by Zabbix agent active*):
- `service.info[]` pro služby DC; `perf_counter_en["\NTDS\…"]` (LDAP vyhledávání, DRA příchozí/odchozí), `perf_counter_en["\DirectoryServices(NTDS)\…"]`.
- PowerShell UserParameters s LLD: `Get-ADReplicationPartnerMetadata -Target $env:COMPUTERNAME` (poslední úspěch, selhání), `Get-ADGroupMember` pro privilegované skupiny (seřazený seznam → položka; trigger na změnu), `Get-ADUser krbtgt -Properties PasswordLastSet`, `Search-ADAccount -LockedOut`, CIM `DfsrReplicatedFolderInfo` (stav SYSVOL).
- `dcdiag /q` a `repadmin /showbackup` jsou pomalé → naplánovaná úloha jednou denně odesílající data přes `zabbix_sender`, s `nodata(26h)`, aby byla vidět i nefunkční úloha.
- `eventlog[Directory Service]`, `eventlog[DFS Replication]`, `eventlog[DNS Server]` se sadou regexů/ID od Integritu (např. 1311, 1388, 1988, 2042, 2089, 13508, 13568, 4013).
- Z proxy v lokalitě: `net.tcp.service[ldap]`, `net.tcp.service[tcp,,636]`, `net.tcp.service[tcp,,88]`, `net.dns.record[<DC>,_ldap._tcp.dc._msdcs.<domain>,SRV]`.
- Kontroly platné pro celou doménu (členství ve skupinách, krbtgt, zamčené účty) spouštět **pouze na PDC emulátoru** (makro šablony `{$AD.ROLE}=pdc`), aby nevznikaly duplicity.

**3. Místo sběru:** aktivní agent → proxy v lokalitě; síťové kontroly z proxy v lokalitě.

**4. Předpoklady na straně zákazníka:** agent MON-SRV na každém DC (bezpečnostní posouzení agenta na DC, viz MON-SRV §10); gMSA nebo kontext LocalSystem agenta pro dotazy do AD jen pro čtení (stačí výchozí oprávnění ke čtení, administrátorská práva nejsou potřeba); modul RSAT AD PowerShell na DC (ve výchozím stavu přítomen); seznam sledovaných privilegovaných skupin (výchozí viz výše); schválený proces změn (aby bylo možné upozornění na změny skupin spárovat s tikety).

**5. Výchozí triggery**

| Trigger | Závažnost | Výchozí hodnota |
|---|---|---|
| Zastavená základní služba DC | Vysoká | – |
| Selhávající replikace | Vysoká | po sobě jdoucí selhání ≥ 1 déle než 60 min, nebo poslední úspěch > `{$AD.REPL.MAXAGE}` = 3 h |
| SYSVOL není sdílen / stav DFS-R není normální | Vysoká | – |
| Časový posun vůči PDC | Průměrná / Vysoká | > 60 s / > 240 s (tolerance Kerberosu 5 min) |
| SRV záznamy domény nelze přeložit | Vysoká | – |
| Nedostupný port LDAP/Kerberos | Vysoká | z proxy, 3 min |
| AD není zálohována | Vysoká | > 7 dní (a událost 2089) |
| Změna členství v privilegované skupině | Průměrná (Vysoká pro Enterprise/Schema Admins) | jakákoli změna; po kontrole se uzavírá ručně |
| Stáří hesla krbtgt | Varování | > 180 dní (položka reportu) |
| Nárůst zamčených účtů | Varování | > 10 za 15 min |
| Denní dcdiag selhal / nepřišel | Průměrná | – |

**6. Závislosti:** triggery DC závisí na dostupnosti hostu v MON-SRV. Alarmy replikace během plánované údržby DC → okno údržby na obou partnerech. Trigger na změnu skupin používá `manual close`, aby byl potvrzen, a ne automaticky vyřešen.

**7. Report:** dostupnost DC, zdraví replikace, plnění požadavků na zálohy AD, změny privilegovaných skupin (kdo/kdy), počty pro hygienu (neaktivní, zamčené účty, administrátorská hesla bez expirace, stáří krbtgt), doporučení.

**8. První vydání:** DC na Windows Server 2016–2025. Samba AD na vyžádání (MON-CUSTOM).

**9. Pracnost:** produktizace **24–40 h** (šablona, sada PowerShell skriptů, sada ID událostí, denní úloha, sekce reportu). Nasazení **0,5–1 h na doménu** nad rámec MON-SRV.

**10. Rizika / otevřené body:** PowerShell UserParameters na DC musí být podepsané a jen pro čtení (code review); seznamy ID událostí je třeba v pilotu doladit. Monitoring členství ve skupinách má vysokou hodnotu pro zákazníky, kterých se týká NIS2.


### 5.6.8 MON-IDSEC · Bezpečnost identit (Entra ID)

**Hranice vůči MON-M365:** *hygiena* licencí a tenantu (stáří synchronizace, tajné klíče aplikací, počet globálních administrátorů, registrace MFA, Secure Score) už je v MON-M365 podle kapitoly 4.14. MON-IDSEC přidává **bezpečnostní události**: věci, kvůli kterým má někdo vstát. Lze ji prodávat jako **rozšiřující úroveň MON-M365**.

**0. Položka katalogu**

| Pole | Návrh |
|---|---|
| Český název | Bezpečnostní monitoring identit (Entra ID) |
| Riziko | 🔴 Kritické (převzetí účtu je nejčastější vstupní bod pro ransomware a podvody s fakturami) |
| Jednotka | tenant / měsíc |
| Cena | 500–1 500 Kč za tenant (podle počtu uživatelů) |
| Text pro zákazníka | Upozorňujeme na vysoce rizikové události identit v Microsoft 365: riziková přihlášení a uživatele označené Microsoftem, použití nouzových administrátorských účtů, nové administrátory, změny bezpečnostních zásad, podezřelá pravidla přeposílání pošty a nové souhlasy pro aplikace. |
| Omezení | Nejde o SOC ani SIEM: upozorňujeme a reportujeme, ale nevyšetřujeme ani nereagujeme, pokud to není dohodnuto zvlášť. Některé kontroly vyžadují licence Entra ID P1/P2. |

**1. Rozsah:**
- Rizikoví uživatelé / detekce rizik (Entra ID Protection) – vysoké a střední.
- Přihlášení **nouzových (break-glass) účtů** (jakékoli přihlášení = upozornění).
- Přidělení **privilegovaných rolí** (Global Admin, Exchange Admin, Privileged Role Admin…) – auditní log adresáře.
- Vytvoření/změna/vypnutí **zásad Conditional Access**; vypnutí výchozích nastavení zabezpečení (security defaults).
- Nový **souhlas pro aplikaci** (OAuth phishing) a nové přihlašovací údaje přidané k service principalům.
- Pravidla **externího přeposílání pošty** / pravidla doručené pošty přeposílající mimo organizaci (Exchange Online; přes nastavení schránky v Graphu nebo audit) *(ověřit proveditelný rozsah v režimu aplikace)*.
- Úspěšná přihlášení ze zemí mimo povolený seznam (P1, logy přihlášení).
- Přihlášení starší (legacy) autentizací (mělo by jich být nula).
- Upozornění vysoké závažnosti z Defender for Office 365 / Defender XDR jsou v MON-EPS (varianta Defender); zde se neduplikují.

**2. Mechanismus na 7.0.31:** šablona Integritu nad **Script items** (stejná multi-tenant aplikace Entra a logika tokenů jako v MON-M365) na externích proxy:

| Data | Endpoint Graphu | Oprávnění (aplikační) | Potřebná licence v tenantu zákazníka |
|---|---|---|---|
| Rizikoví uživatelé / detekce | `/identityProtection/riskyUsers`, `/riskDetections` | IdentityRiskyUser.Read.All, IdentityRiskEvent.Read.All | P2 pro plné detaily (P1: omezeně) |
| Audit adresáře (role, CA, souhlasy, údaje SP) | `/auditLogs/directoryAudits?$filter=activityDateTime ge …` | AuditLog.Read.All | libovolná (uchování 7 dní zdarma / 30 dní s P1) |
| Přihlášení (break-glass, země, legacy autentizace) | `/auditLogs/signIns?$filter=…` | AuditLog.Read.All | P1 |
| Snímek zásad CA | `/identity/conditionalAccess/policies` | Policy.Read.All | P1 |

Data typu události se dotazují každých 5 min s překrývajícím se 10minutovým oknem; každá událost se stane **položkou typu log** bez LLD (JSON na událost) s triggery nad obsahem; duplicity se v předzpracování filtrují podle ID události (JavaScript si pamatuje naposledy viděná ID přes předchozí hodnotu položky). Zásady CA se hashují; změna hashe vyvolá trigger.

**Alternativa (silnější, dražší):** diagnostická nastavení Entra → Log Analytics → analytika Microsoft Sentinel / Defender XDR. Lepší detekce, ale náklady na ingestovaný GB v každém tenantu a jiné znalosti. Doporučení: v prvním vydání **dotazování ze Zabbixu na zhruba 10 nejvýznamnějších událostí**, Sentinel jako samostatná budoucí služba „managed security“.

**3. Místo sběru:** externí proxy.

**4. Předpoklady:** souhlas administrátora (admin consent) s dalšími oprávněními pro multi-tenant aplikaci Integritu; seznam nouzových účtů; povolený seznam zemí; přehled licencí Entra ID P1/P2 u každého zákazníka (určuje, které kontroly jsou aktivní – příznaky v makrech `{$IDSEC.P1}`, `{$IDSEC.P2}`).

**5. Výchozí triggery**

| Trigger | Závažnost |
|---|---|
| Přihlášení nouzového účtu | Katastrofa |
| Uživatel s vysokým rizikem / detekce vysokého rizika | Vysoká |
| Přidělena privilegovaná role | Vysoká (Global Admin) / Průměrná (ostatní) |
| Změna nebo vypnutí zásady CA, vypnutí security defaults | Průměrná |
| Souhlas pro novou multi-tenant aplikaci s vysoce privilegovanými oprávněními | Průměrná |
| Nové přihlašovací údaje u service principalu | Varování |
| Vytvořeno pravidlo automatického přeposílání ven | Vysoká |
| Přihlášení ze země mimo povolený seznam (úspěšné) | Průměrná |
| Přihlášení starší autentizací | Varování |
| Selhávající dotazování Graphu / chybějící souhlas | Průměrná (interní pro Integrit) |

**6. Ochrana proti falešným poplachům:** očekávané administrátorské změny se potvrzují proti úkolu v Planneru; u cestování by dočasný povolený seznam zemí v makru pro každého uživatele byl příliš podrobný, proto je trigger na země na úrovni tenantu se seznamem výjimek.

**7. Report:** události identit za měsíc, trend rizik, změny administrátorů, změny CA, doporučení (např. „3 administrátoři bez MFA odolného proti phishingu“).

**8. První vydání:** pouze Entra ID (Google Workspace se nenavrhuje).

**9. Pracnost:** **32–48 h** (vzor dotazování událostí, logika deduplikace, triggery, report). Nasazení **0,5–1 h na tenant**, pokud už existuje souhlas pro MON-M365.

**10. Rizika / otevřené body:** řešení mimo pracovní dobu (přihlášení nouzového účtu ve 2 hodiny ráno vyžaduje člověka); ochrana osobních údajů: data o přihlášeních jsou osobní údaje → musí je pokrývat smlouva o zpracování se zákazníkem.


### 5.6.9 MON-CERT · Interní certifikáty, PKI a tajné klíče

**Hranice:** veřejné certifikáty webů a domén jsou v MON-WEB / MON-DNS; tajné klíče aplikací Entra v MON-M365. MON-CERT pokrývá **vše ostatní, co potichu vyprší**.

**0. Položka katalogu**

| Pole | Návrh |
|---|---|
| Český název | Hlídání certifikátů a interní PKI |
| Riziko | 🟠 Vysoké (vypršený interní certifikát nebo CRL zastaví VPN, Wi-Fi 802.1X, RDS, LDAPS, Intune pro iPhony) |
| Jednotka | zákazník / měsíc, odstupňováno (do 10 / 25 / 50 koncových bodů) |
| Cena | 200–600 Kč za zákazníka |
| Text pro zákazníka | Sledujeme expiraci certifikátů a tokenů, na kterých vaše systémy interně závisí: certifikáty VPN a firewallu, certifikáty RDS a poštovního serveru, vaši interní certifikační autoritu a její seznamy odvolaných certifikátů a tokeny Apple pro správu iPhonů. Varování dostanete týdny předem. |
| Omezení | Upozorňujeme a reportujeme; obnova certifikátů je samostatná služba, pokud není dohodnuto jinak. |

**1. Rozsah:** TLS certifikáty na interních HTTPS endpointech (RDS Gateway, Exchange/OWA, administrace NAS/firewallu, správa tiskáren, webové ERP); certifikáty STARTTLS (SMTP, LDAPS 636, RDP 3389); certifikáty v úložišti počítače Windows na serverech (expirující za < N dní, včetně certifikátů pro podepisování kódu/SAML); **AD CS**: expirace certifikátu CA, **příští aktualizace / stáří publikace CRL** na každé CDP URL, stav služby CA, neúspěšné žádosti; **certifikát Apple Push Notification (APNs), token ADE (DEP) a token VPP** v Intune (každoroční obnova; vypršený certifikát APNs vynutí opětovnou registraci každého zařízení Apple); heuristika zdraví automatizace Let's Encrypt (certifikát starší než 60 dní na endpointu, který se má automaticky obnovovat každých 60 dní → obnova nefunguje).

**2. Mechanismus na 7.0.31**

| Kontrola | Jak | Oficiální? |
|---|---|---|
| HTTPS endpointy (interní) | *Website certificate by Zabbix agent 2* (`web.certificate.get`) – spouštěno z **agenta 2 na proxy v lokalitě**, který slouží jako sondovací host | Ano |
| STARTTLS / LDAPS / RDP | Externí skript na proxy (`openssl s_client -starttls smtp|ldap` …, RDP přes `-connect host:3389` s TLS) vracející `notAfter` | Vytváří Integrit (malé) |
| Úložiště počítače Windows | PowerShell UserParameter s LLD (`Get-ChildItem Cert:\LocalMachine\My`), odfiltruje self-signed/nerelevantní certifikáty | Vytváří Integrit |
| CA a CRL v AD CS | Na CA: `service.info[CertSvc]`, UserParameter založený na `certutil`; z proxy: stažení CRL z HTTP CDP a parsování `nextUpdate` (`openssl crl`) | Vytváří Integrit |
| Tokeny Apple v Intune | Graph: `/deviceManagement/applePushNotificationCertificate` (expirationDateTime), `/deviceAppManagement/vppTokens`, tokeny ADE (`depOnboardingSettings`, beta endpoint) – oprávnění DeviceManagementServiceConfig.Read.All, DeviceManagementApps.Read.All | Vytváří Integrit (Script items) |

**3. Místo sběru:** proxy v lokalitě (interní endpointy, CDP), agenti (úložiště, CA), externí proxy (Intune).

**4. Předpoklady:** seznam interních endpointů (prvotní zjištění: sken známých hostů na portech 443/636/3389/25 z proxy při onboardingu, poté potvrzení se zákazníkem); agent na serveru CA (MON-SRV); souhlas pro Intune.

**5. Výchozí triggery**

| Trigger | Závažnost | Výchozí hodnota |
|---|---|---|
| Certifikát brzy vyprší | Varování / Průměrná / Vysoká | < 30 / < 14 / < 3 dny |
| Certifikát vypršel nebo má neplatný řetězec | Vysoká | – |
| Příští aktualizace CRL | Vysoká | < 24 h před `nextUpdate`, nebo CRL nedostupný 1 h |
| Certifikát CA brzy vyprší | Průměrná | < 180 dní |
| Token APNs / ADE / VPP brzy vyprší | Průměrná / Vysoká | < 30 / < 7 dní |
| Certifikát ACME nebyl obnoven | Varování | stáří > 60 dní |

**7. Report:** kalendář certifikátů pro zákazníka (příštích 90 dní), obnovy provedené v měsíci.

**9. Pracnost:** produktizace **16–24 h**. Nasazení **0,5–1,5 h na zákazníka** (inventura endpointů).

**10. Otevřené body:** spojit s kontrolou veřejných certifikátů z MON-DNS do jedné sekce reportu „kalendář certifikátů“, aby zákazník viděl jeden seznam.


### 5.6.10 MON-MAIL · Tok pošty, zabezpečení poštovní domény a poštovní servery

**0. Položka katalogu**

| Pole | Návrh |
|---|---|
| Český název | Monitoring e-mailové komunikace |
| Riziko | 🟠 Vysoké (ztracená nebo zpožděná pošta, pošta končící ve spamu, podvržení domény pro podvody s fakturami) |
| Jednotka | poštovní doména / měsíc; on-prem poštovní server jako doplněk za server |
| Cena | **Basic** (DNS/bezpečnostní záznamy, MX, blacklisty): 100–250 Kč za doménu. **Plus** (end-to-end test doručení každých 15 min): 300–600 Kč za doménu. **Poštovní server** (Exchange/Postfix on-prem): 300–600 Kč za server |
| Text pro zákazníka | Kontrolujeme, že se e-maily do vaší domény a z ní skutečně doručují a jak dlouho to trvá, že je vaše doména chráněna proti podvržení (SPF, DKIM, DMARC), že jsou vaše poštovní servery dostupné s platnými certifikáty a že vaše odesílací adresy nejsou na spamových blacklistech. |
| Omezení | Nefiltrujeme spam ani malware a vaši poštu nečteme; test využívá vyhrazenou testovací schránku. |

**1. Rozsah**

| Úroveň | Kontroly |
|---|---|
| **Basic** (zvenku, bez přístupu do poštovního systému zákazníka) | MX záznamy se přeloží a odpovídají na TCP 25; platný SMTP banner a **certifikát STARTTLS**; **SPF** existuje, je syntakticky platný, ≤ 10 DNS lookupů, končí `-all`/`~all`; **DMARC** existuje a jeho politika (`p=none` → doporučení, chybí → upozornění); existují selektory **DKIM** (pro M365: `selector1`/`selector2`); MTA-STS / TLS-RPT (jen do reportu); odchozí IP adresy (ze SPF / známých bran) na **DNS blacklistech** |
| **Plus** | **End-to-end sonda doručení**: jedinečná testovací zpráva odeslaná každých 15 min ze sondovací schránky Integritu do testovací schránky v doméně zákazníka (příchozí cesta) a z testovací schránky zákazníka zpět (odchozí cesta); měří se latence doručení; detekuje se „nedoručeno do N min“ a „skončilo v nevyžádané poště“ |
| **Poštovní server** (on-prem) | Exchange: služby, **délka fronty** transportu, stav připojení databází, události back-pressure, certifikát; Postfix: velikost fronty (`mailq`), počet odložených zpráv, služba; poštovní brány (appliance) přes SNMP/API na vyžádání |
| Není součástí | Sledování zpráv v Exchange Online (vyžaduje Exchange Online PowerShell `Get-MessageTraceV2` s certifikátem aplikace: možné později, ne v prvním vydání); zpracování agregovaných DMARC reportů (doporučujeme specializovanou DMARC službu, viz varianty) |

**2. Mechanismus na 7.0.31**

| Kontrola | Jak | Oficiální? |
|---|---|---|
| MX, SPF, DMARC, DKIM, MTA-STS | Jednoduché kontroly `net.dns.record[]` + předzpracování v JavaScriptu (parser SPF počítající lookupy potřebuje rekurzivní překlad → externí skript) | Vytváří Integrit (sdílí DNS kód s MON-DNS) |
| SMTP + certifikát STARTTLS | `net.tcp.service[smtp]` + externí skript (`openssl s_client -starttls smtp`) vracející `notAfter`, protokol a stav řetězce | Vytváří Integrit (sdíleno s MON-CERT) |
| Blacklisty | Externí skript dotazující vybranou sadu DNSBL (Spamhaus ZEN přes **klíč DQS**, Barracuda, SpamCop, UCEProtect L1, volitelně Microsoft SNDS) přes vlastní resolver Integritu – veřejné DNSBL odmítají dotazy z velkých veřejných resolverů a Spamhaus pro komerční použití vyžaduje placené předplatné DQS | Vytváří Integrit |
| End-to-end sonda (zákazníci M365) | Script item na externí proxy využívající **Graph**: `sendMail` ze sondovací schránky, poté `messages?$filter=…` v cílové schránce pro nalezení tokenu, načtení `receivedDateTime`, kontrola složky (Doručená pošta vs. Nevyžádaná pošta), smazání testovací zprávy. Přístup ke schránkám omezen pomocí **Exchange Online RBAC for Applications** pouze na testovací schránky (`Mail.Send`, `Mail.ReadWrite` s omezeným rozsahem) | Vytváří Integrit |
| End-to-end sonda (pošta mimo M365) | Sonda odesílá přes SMTP submission; testovací schránka zákazníka se čte přes IMAP (externí skript) | Vytváří Integrit, na vyžádání |
| Exchange on-prem | *Microsoft Exchange Server 2016 by Zabbix agent (active)* – oficiální pro 2016; pro 2019/SE použitelná pro většinu čítačů *(ověřit)*; plus PowerShell položky Integritu: `Get-Queue`, `Get-MailboxDatabaseCopyStatus`, `Get-ExchangeCertificate` | Ano + Integrit |
| Postfix | `UserParameter` nad `postqueue -j` / `mailq` | Vytváří Integrit |

**Sondovací schránky:** pro příjem a přístup přes Graph stačí u každého zákazníka sdílená schránka (bez licence). Sondovací schránka na straně Integritu je v tenantu Integritu (nebo v samostatné monitorovací doméně Integritu), aby cesta zvenku dovnitř byla skutečná.

**3. Místo sběru:** externí proxy (DNS, SMTP, blacklisty, sonda přes Graph); proxy v lokalitě / agent pro on-prem servery.

**4. Předpoklady na straně zákazníka:** seznam poštovních domén a odchozích IP adres/bran; pro Plus: sdílená testovací schránka + souhlas s omezenými oprávněními Graphu (multi-tenant aplikace Integritu) a výjimka v transportním pravidle, aby testovací zprávy nekončily v karanténě (nebo naopak končily, pokud je cílem testovat filtr – je třeba se dohodnout); pro poštovní servery: agent MON-SRV a role Exchange jen pro čtení pro PowerShell položky.

**5. Výchozí triggery**

| Trigger | Závažnost | Výchozí hodnota |
|---|---|---|
| Chybí MX / MX neodpovídá na portu 25 | Vysoká | 2 ze 2 externích proxy, 5 min |
| Certifikát STARTTLS brzy vyprší / je neplatný | Průměrná / Vysoká | < 14 dní / vypršel |
| SPF chybí nebo je neplatný / > 10 lookupů | Průměrná | – |
| Chybí DMARC | Varování | `p=none` → Informace (report) |
| Chybí selektor DKIM (u nakonfigurovaných selektorů) | Průměrná | – |
| Odchozí IP na blacklistu | Vysoká (hlavní seznamy) / Varování (menší seznamy) | váha podle seznamu |
| Testovací zpráva nedoručena (příchozí nebo odchozí) | Vysoká | nenalezena po `{$MAIL.E2E.TIMEOUT}` = 30 min, 2 po sobě jdoucí běhy |
| Pomalé doručení | Varování | > 10 min |
| Testovací zpráva v nevyžádané poště | Průměrná | – |
| Transportní fronta Exchange | Průměrná / Vysoká | > 100 / > 500 zpráv po dobu 15 min |
| Databáze Exchange odpojena / kopie není v pořádku | Katastrofa / Vysoká | – |
| Odložená fronta Postfixu | Průměrná | > 50 po dobu 30 min |

**6. Závislosti / falešné poplachy:** sonda závisí na vlastní poště Integritu (pokud má tenant Integritu incident, selžou sondy všech zákazníků → nadřazenou závislostí je položka „vlastní test sondy“ mezi dvěma schránkami Integritu). Servisní incidenty Microsoft 365 (stav služeb v MON-M365) jsou nadřazené triggerům odchozí/příchozí sondy. Výsledky blacklistů kolísají → vyžadovat 2 po sobě jdoucí pozitivní kontroly.

**7. Report:** úspěšnost doručení a medián / 95. percentil latence pro každý směr, události na blacklistech, skóre zabezpečení domény (splněné SPF/DKIM/DMARC/MTA-STS), doporučení (např. „změnit DMARC z p=none na quarantine“).

**8. Varianty**

| Varianta | Hodnocení |
|---|---|
| Vše postavit v Zabbixu (viz výše) | **Doporučeno** pro Basic i Plus: využívá aplikaci Graph, kterou Integrit stejně potřebuje pro MON-M365 |
| Specializovaná DMARC SaaS (např. dmarcian, Valimail, EasyDMARC, Red Sift) pro agregované reporty | Volitelný doplněk k přeprodeji; Zabbix v případě zájmu načítá jen její souhrn (přes API) |
| SaaS třetí strany pro monitoring toku pošty | Nedoporučeno: duplikuje sondu za dodatečné náklady |

**První vydání:** Basic + Plus pro zákazníky Microsoft 365 (vzhledem k zaměření Integritu na Microsoft většina báze). Exchange on-prem jen tam, kde ještě je (verze 2016 i 2019 jsou od 14. 10. 2025 bez podpory – argument pro prodej migrace).

**9. Pracnost:** produktizace Basic **16–24 h** (velká část sdílena s MON-DNS), Plus **24–32 h** (sonda přes Graph, omezená oprávnění, deduplikace/úklid), poštovní server **8–16 h**. Nasazení Basic **0,25 h na doménu**, Plus **1 h na doménu**, server **0,5–1 h**.

**10. Rizika / otevřené body:** sonda pracuje se schránkami zákazníka → povinné je smluvní ošetření a nejmenší nutná oprávnění; náklady na Spamhaus DQS; limity odesílání v Graphu jsou daleko nad 96 sondami denně, to není problém. Rozhodnout, zda se Basic stane součástí MON-DNS (doporučení: **ano** – prodávat „Zabezpečení domény a pošty“ jako jeden produkt na úrovni domény a Plus jako samostatnou položku (SKU) pro tok pošty).


### 5.6.11 MON-SECEVT · Základní bezpečnostní události

**0. Položka katalogu**

| Pole | Návrh |
|---|---|
| Český název | Základní bezpečnostní události serverů |
| Riziko | 🔴 Kritické (známky probíhajícího útoku: mazání logů, nový administrátor, útok hrubou silou) |
| Jednotka | server / měsíc (doplněk k MON-SRV); řadiče domény přes MON-AD |
| Cena | 100–200 Kč za server |
| Text pro zákazníka | Na serverech, které už monitorujeme, upozorňujeme na krátký seznam vysoce rizikových bezpečnostních událostí: vymazání auditního logu, nový místní administrátor, instalace nové služby, opakovaná neúspěšná přihlášení, přihlášení ke vzdálené ploše z internetu a detekce Microsoft Defenderu. |
| Omezení | **Nejde o SIEM ani SOC**: žádný archiv logů, žádná korelace napříč systémy, žádné vyšetřování 24/7. Pro logování na úrovni NIS2 je potřeba specializovaná logovací platforma (viz varianty). |

**1. Rozsah (Windows, ID událostí):** 1102 vymazání bezpečnostního logu; 4720 vytvoření uživatele, 4732/4728/4756 přidání člena do privilegované/místní administrátorské skupiny; 4625 série neúspěšných přihlášení; 4740 zamčení účtu; 4624 typ 10 (RDP) ze zdroje mimo RFC1918; 7045/4697 instalace nové služby; 4719 změna auditní politiky; 4698 vytvoření naplánované úlohy (filtrováno); Microsoft Defender Antivirus 1116/1117 (detekce / akce), 5001 (vypnutá ochrana v reálném čase). **Linux:** série neúspěšných ověření sshd, `sudo` na root neočekávanými uživateli, nový uživatel/skupina (změna hashe `/etc/passwd` přes `vfs.file.cksum`), vymazání logu auditd.

**2. Mechanismus na 7.0.31:** šablona Integritu nad agentem 2 (aktivní): `eventlog[Security,,,,"^(1102|4720|4728|4732|4756|4719|4697|4698)$",,skip]`, `eventlog[System,,,,"^7045$",,skip]`, provozní log Defenderu; pro série čítací položky (`eventlog.count[]` *(ověřit na 7.0)*), takže se ukládají jen počty, ne každá událost; na Linuxu `log[]`/`log.count[]` nad `/var/log/auth.log` nebo journalem. Předpoklad: správná **auditní politika** (Advanced Audit Policy přes GPO) – jinak se události vůbec nezapisují; Integrit dodá základní GPO.

**3. Místo sběru:** aktivní agent → proxy v lokalitě.

**5. Výchozí triggery:** vymazání logu (Katastrofa); přidání člena do Administrators/privilegované skupiny (Vysoká; ruční uzavření); instalace nové služby (Průměrná; povolený seznam známých instalátorů přes regex v makru); neúspěšná přihlášení > 20 / 5 min (Průměrná), > 100 (Vysoká); přihlášení RDP z veřejné IP (Vysoká); detekce Defenderu (Vysoká) / vypnutá ochrana v reálném čase (Vysoká); změna auditní politiky (Průměrná).

**6. Falešné poplachy:** nasazování softwaru vytváří služby a naplánované úlohy → povolené seznamy a okna údržby; administrátorská práce Integritu → potvrzení proti tiketu.

**7. Report:** počet bezpečnostních událostí podle typu, významné události s časem a účtem, soulad auditní politiky na jednotlivých serverech.

**8. Varianty**

| Varianta | Hodnocení |
|---|---|
| Základní sada událostí v Zabbixu (viz výše) | **Doporučeno pro první vydání**: levné, využívá stávajícího agenta, pokrývá „zjevné“ signály útoku |
| Wazuh (open source SIEM/XDR) jako samostatná platforma Integritu | Další krok pro nabídku „managed security“: uchovávání logů, integrita souborů, detekce zranitelností, mapování na compliance; upozornění z Wazuhu lze předávat do Zabbixu/Planneru |
| Microsoft Sentinel / Defender XDR v tenantu zákazníka | Pro zákazníky silně orientované na Microsoft s E5/Business Premium; náklady za GB |
| Graylog / Elastic jen pro uchovávání logů | Když jde o povinnost logování podle NIS2, ne o detekci |

**9. Pracnost:** produktizace **16–24 h** (sada událostí, základní auditní GPO, triggery, povolené seznamy). Nasazení **0,25 h na server** + zavedení GPO u zákazníka (účtováno jednorázově).

**10. Otevřené body:** rozhodnout o řešení bezpečnostních událostí se závažností Katastrofa mimo pracovní dobu (většina zákazníků z řad SMB očekává telefonát). Tato služba je přirozeným vstupem do budoucí řady managed security; na pozicování záleží víc než na technologii.


### 5.6.12 MON-EXPOSURE · Vnější útočná plocha

**0. Položka katalogu**

| Pole | Návrh |
|---|---|
| Český název | Monitoring vnější expozice (otevřené porty a služby z internetu) |
| Riziko | 🔴 Kritické (vystavené RDP, SMB nebo zranitelný VPN portál jsou hlavním vstupním bodem ransomwaru) |
| Jednotka | veřejná IP / měsíc (balíčky: do 4 / 16 IP) |
| Cena | 100–200 Kč za IP, minimálně 300 Kč za zákazníka |
| Text pro zákazníka | Z internetu pravidelně kontrolujeme, které služby jsou na vašich veřejných adresách dostupné, a okamžitě upozorníme, když se objeví něco rizikového, například vzdálená plocha, sdílení souborů nebo administrační rozhraní, nebo když VPN portál firewallu běží ve verzi se známou zranitelností. |
| Omezení | Nejde o penetrační test ani o úplný sken zranitelností; kontrolujeme jen dohodnuté veřejné adresy s písemným souhlasem zákazníka. |

**1. Rozsah:** otevřené TCP porty na dohodnutých veřejných IP oproti schválenému výchozímu stavu (baseline); vysoce rizikové služby (3389 RDP, 445 SMB, 135/139, 21, 23, 1433, 3306, 5432, 5900 VNC, administrační panely 8080/8443/4443/10443, 161 SNMP UDP); konfigurace TLS vystavených služeb HTTPS/VPN (zastaralé TLS 1.0/1.1, slabé šifry, vypršené certifikáty); **verze firmwaru** firewallu/VPN **oproti bezpečnostním upozorněním výrobců** (seznam CISA KEV pro aktivně zneužívané CVE: Fortinet, Ivanti, Cisco ASA, Palo Alto, SonicWall, Citrix); IP adresy uvedené v SPF na blacklistech (s MON-MAIL).

**2. Mechanismus na 7.0.31:**
- **Rychlá kontrola (každých 15–60 min):** položky `net.tcp.service[tcp,<ip>,<port>]` z **externích proxy** pro seznam vysoce rizikových portů, LLD nad seznamem IP zákazníka → okamžité upozornění, když se rizikový port otevře.
- **Úplný sken (týdně):** `nmap` top-1000 TCP + vybrané UDP a `testssl.sh` pro TLS, spouštěné naplánovanou úlohou na **vyhrazeném skenovacím VM** (ne na Zabbix proxy, aby skenovací provoz a právní expozice zůstaly oddělené). Výsledky se posílají do Zabbixu přes `zabbix_sender` jako JSON; závislé položky je porovnávají s výchozím stavem (seznam v makru pro každou IP).
- **Firmware vs. bezpečnostní upozornění:** verzi firmwaru už sbírá MON-NET (SNMP/API). Denní úloha Integritu stáhne katalog CISA KEV (JSON) a PSIRT feedy výrobců, namapuje výrobce/verzi a nastaví u každého zařízení položku „přítomna známá zneužívaná zranitelnost“. Začít s výrobci firewallů, které se vyskytují u zákazníků.

**3. Místo sběru:** externí proxy + skenovací VM Integritu (obojí mimo sítě zákazníků, se zveřejněnými zdrojovými IP).

**4. Předpoklady:** **písemný souhlas** ve smlouvě se seznamem IP (skenování bez něj je právní a smluvní riziko; poskytovatelé hostingu ho navíc mohou označit); schválený výchozí stav otevřených portů; povolení skenovacích IP Integritu v IPS/geoblokaci zákazníka (jinak jsou výsledky blokovány nebo se spouštějí upozornění na straně zákazníka).

**5. Výchozí triggery:** dostupný vysoce rizikový port (Vysoká; RDP/SMB = Katastrofa); nový otevřený port mimo výchozí stav (Průměrná); zastaralý protokol TLS / slabá šifra (Varování); firmware firewallu se známou zneužívanou zranitelností (Katastrofa); sken nedokončen 8 dní (Průměrná, interní pro Integrit).

**7. Report:** tabulka expozice pro každou IP (otevřené služby, změna oproti minulému měsíci), hodnocení TLS, nálezy zranitelného firmwaru a stav nápravy – přímo použitelné jako doklad pro povinnost zákazníka řídit zranitelnosti podle NIS2.

**8. Varianty:** postavit podle popisu výše (**doporučeno**: levné, plná kontrola, kombinuje se s daty o firmwaru z MON-NET); nebo přeprodávat komerční EASM/skener (Tenable, Qualys, Greenbone/OpenVAS v self-hosted provozu) pro zákazníky, kteří potřebují autentizované skenování zranitelností – samostatná budoucí služba.

**9. Pracnost:** produktizace **24–40 h** (skenovací VM, skenovací úlohy, logika výchozího stavu, mapování KEV pro 2–3 výrobce firewallů, report). Nasazení **0,5 h na zákazníka**.

**10. Otevřené body:** šablona smlouvy (souhlas, seznam IP, okno pro skenování); zda vlastní ISP/hosting Integritu odchozí skenování povoluje.


### 5.6.13 MON-MDM · Soulad správy zařízení (Intune)

**Hranice:** antivir a upozornění Defenderu jsou v MON-EPS; expirace tokenů Apple v MON-CERT. MON-MDM pokrývá **stav správy flotily zařízení** a je přirozeným místem pro **soulad pracovních stanic s aktualizacemi** (servery jsou v MON-SRV).

**0. Položka katalogu**

| Pole | Návrh |
|---|---|
| Český název | Monitoring správy koncových zařízení (Intune) |
| Riziko | 🟠 Vysoké (nešifrované, neaktualizované nebo nespravované notebooky = riziko úniku dat a ransomwaru) |
| Jednotka | tenant / měsíc + za spravované zařízení |
| Cena | 300 Kč za tenant + 10–30 Kč za zařízení |
| Text pro zákazníka | U zařízení spravovaných přes Microsoft Intune hlídáme soulad: zařízení, která se přestala hlásit, nejsou šifrovaná, běží na zastaralé nebo nepodporované verzi Windows, nemají aktualizace nebo nesplňují zásady dodržování předpisů (compliance). |
| Omezení | Pokrývá pouze zařízení spravovaná přes Intune; oprava zařízení je samostatná služba. |

**1. Rozsah:** počty zařízení (spravovaná, vyhovující, nevyhovující, v ochranné lhůtě); neaktivní zařízení (poslední synchronizace > 14 / 30 dní); stav šifrování BitLocker/FileVault; verze/build OS oproti minimu (např. Windows 10 bez podpory od 14. 10. 2025, data konce podpory feature release Windows 11); soulad s aktualizačními okruhy Windows / stáří kvalitativních aktualizací *(zdroj: reporty Intune přes Graph; reporty Windows Update for Business vyžadují Log Analytics – ověřit, který zdroj se použije)*; selhání přiřazení profilů Autopilot; zdraví konektorů Intune (NDES/Certificate connector, Exchange connector), pokud se používají; selhání instalace povinných aplikací (report).

**2. Mechanismus na 7.0.31:** šablona Integritu se Script items na externích proxy využívající stejnou multi-tenant aplikaci Entra (oprávnění: DeviceManagementManagedDevices.Read.All, DeviceManagementConfiguration.Read.All, DeviceManagementServiceConfig.Read.All, DeviceManagementApps.Read.All). **Agregace za tenant, detail na vyžádání** – stejný princip jako u MON-EPS: počty jako položky, seznamy zařízení jako text pro report, problémy jednotlivých zařízení jen pro „nešifrováno“ a „neaktivní > 30 dní“ u zařízení označených jako kritická.

**3. Místo sběru:** externí proxy.

**4. Předpoklady:** používání Intune (M365 Business Premium nebo E3/E5); souhlas administrátora; definice „kritických zařízení“ a přijatelné doby neaktivity.

**5. Výchozí triggery:** nevyhovující zařízení > `{$MDM.NONCOMPLIANT.MAX}` nebo > 10 % (Průměrná); nešifrované zařízení (Vysoká); neaktivní zařízení > N (Varování); OS pod minimem (Varování); konektor není v pořádku (Vysoká); selhání API (Průměrná, interní).

**7. Report:** trend souladu, změny v inventáři zařízení, seznamy neaktivních/nešifrovaných/zastaralých zařízení, soulad s aktualizacemi.

**8. Varianty:** Intune (doporučeno, zaměření na Microsoft). Zákazníci s RMM (NinjaOne, Datto RMM, N-able, Action1) → API daného RMM může na vyžádání plnit stejné položky přes konektor.

**9. Pracnost:** produktizace **24–32 h**. Nasazení **0,5–1 h na tenant**, pokud už existuje souhlas pro MON-M365.

**10. Otevřené body:** rozhodnout, zda se MON-MDM a MON-EPS budou prodávat společně jako balíček „Endpoint“ (doporučení: ano – Endpoint Basic = EPS, Endpoint Plus = EPS + MDM).

### 5.6.14 MON-CLOUD · Prostředky veřejného cloudu (Azure, AWS, GCP)

**0. Položka katalogu**

| Pole | Návrh |
|---|---|
| Český název | Monitoring cloudových prostředků (Azure, AWS) |
| Riziko | 🟠 Vysoké (cloudové VM a databáze nesou produkční provoz; nekontrolované náklady) |
| Jednotka | předplatné (Azure) / účet (AWS) za měsíc, odstupňováno podle počtu monitorovaných prostředků (≤ 10 / ≤ 30 / více) |
| Cena | 500–1 500 Kč za předplatné/účet + 50–150 Kč za každý monitorovaný prostředek nad rámec pásma |
| Text pro zákazníka | Sledujeme vaše prostředky v Azure (nebo AWS) na základě monitorovacích dat samotného poskytovatele cloudu: virtuální servery, databáze, úložiště, zálohy a útratu. O zastaveném virtuálním serveru, databázi bez volného místa, neúspěšné cloudové záloze nebo překročení rozpočtu se dozvíte dřív, než to začne bolet. |
| Omezení | Využívá metriky platformy poskytovatele. Operační systém uvnitř cloudových VM vyžaduje MON-SRV. Data o nákladech přicházejí se zpožděním poskytovatele (obvykle až 24 h). |

**1. Rozsah:**
- **Azure:** VM a VM scale sets (stav napájení, CPU, disk, síť, dostupnost); Azure SQL (DB, DTU, serverless, Managed Instance), MySQL a PostgreSQL Flexible Server, Cosmos DB for MongoDB (stav, % úložiště, DTU/CPU, připojení, deadlocky); storage accounts (dostupnost, kapacita, latence); **úlohy Azure Backup** (Recovery Services / Backup vaults: neúspěšné úlohy); **Cost Management** (náklady od začátku měsíce, prognóza vs. rozpočet); Azure **Resource Health / Service Health** (vlastní řešení); doporučení Azure Advisor (pouze do reportu, vlastní řešení).
- **AWS:** EC2 (status checks, CPU credits, svazky EBS), RDS, S3, ECS, ELB, Lambda, **úlohy AWS Backup vault**, alarmy CloudWatch jako položky; náklady přes Cost Explorer (vlastní řešení).
- **GCP:** Compute Engine a Cloud SQL (oficiální šablona) — na vyžádání.
- Microsoft 365 sem nepatří (MON-M365); zabezpečení Entra ID řeší MON-IDSEC.

**2. Mechanismus na verzi 7.0.31**

| Cloud | Jak | Oficiálně v release/7.0? |
|---|---|---|
| Azure | ***Azure by HTTP*** (hlavní šablona s discovery) + podřízené šablony: *Azure Virtual Machine*, *VM Scale Set*, *MySQL Flexible/Single*, *PostgreSQL Flexible/Single*, *Microsoft SQL Database / DTU / Serverless*, *SQL Managed Instance*, *Cosmos DB for MongoDB*, ***Azure Backup Jobs***, ***Azure Cost Management*** — všechny „by HTTP“, bez externích skriptů | Ano |
| Azure Service/Resource Health, Advisor | Skriptové položky nad `Microsoft.ResourceHealth/availabilityStatuses` a Advisor API | Vytváří Integrit |
| AWS | ***AWS by HTTP*** (discovery EC2, RDS, ECS, ELB, Lambda, S3, backup vaults) + podřízené šablony | Ano |
| Náklady AWS | Skriptová položka nad Cost Explorer `GetCostAndUsage` (každé volání AWS účtuje, cca 0,01 USD → dotazovat jednou denně) | Vytváří Integrit |
| GCP | *GCP by HTTP* (Compute Engine, Cloud SQL) | Ano |

**Model přístupu (multi-tenant):**

| Varianta | Jak | Hodnocení |
|---|---|---|
| **Azure Lighthouse** | Zákazník deleguje předplatná do tenantu Integritu; jeden service principal Integritu s rolemi **Reader + Monitoring Reader + Cost Management Reader** vidí všechna delegovaná předplatná | **Doporučeno** pro Azure: jedny přihlašovací údaje, zákazník může přístup odebrat, je viditelný v portálu zákazníka, standardní vzor pro MSP |
| Service principal pro každé předplatné zákazníka | Samostatný secret pro každého zákazníka | Záložní varianta, pokud zákazník Lighthouse odmítne |
| AWS cross-account IAM role | Zákazník vytvoří roli jen pro čtení (`ReadOnlyAccess` nebo užší `CloudWatchReadOnlyAccess` + práva describe pro jednotlivé služby), které důvěřuje účet Integritu; šablona používá assume-role *(ověřit podporu převzetí role v šabloně 7.0; jinak IAM uživatel s přístupovým klíčem pro každého zákazníka)* | Doporučeno pro AWS |

**3. Místo sběru:** externí proxy (cloudová API z internetu).

**4. Předpoklady:** onboarding do Lighthouse (ARM šablonu dodá Integrit) nebo vytvoření role; seznam předplatných/účtů a skupin prostředků/tagů v rozsahu (dev/test vyřadit, aby zůstal nízký počet i šum); měsíční rozpočet pro každé předplatné; které VM dostanou navíc MON-SRV.

**5. Výchozí triggery**

| Trigger | Závažnost | Výchozí hodnota |
|---|---|---|
| VM nedostupný / neočekávaně zastavený / selhaný status check | Vysoká | triggery šablony, filtrované na prostředky otagované jako v rozsahu |
| Využití úložiště DB | Průměrná / Vysoká | > 85 % / > 95 % |
| Trvale vysoké CPU/DTU databáze | Varování | > 90 % po 30 min |
| Neúspěšná zálohovací úloha | Vysoká | šablony Azure Backup Jobs / AWS Backup vault |
| Náklady od začátku měsíce / prognóza nad rozpočtem | Varování / Průměrná | prognóza > 100 % / skutečnost > 100 % `{$CLOUD.BUDGET}` |
| Denní anomálie nákladů | Varování | den > 2× sedmidenní průměr |
| Zhoršený stav v Resource Health | Průměrná | – |
| Selhávající přístup k API (odebraný souhlas/role) | Průměrná (interní pro Integrit) | – |

**6. Závislosti / falešná upozornění:** incidenty platformy Azure (Service Health) jako nadřazené triggerům prostředků; VM s autoscalingem nebo deallokované podle plánu potřebují výjimku na základě tagu (`zabbix:ignore-power`) nebo makro s plánem; zpoždění dat o nákladech → vyhodnocovat jednou denně.

**7. Report:** dostupnost klíčových prostředků, úspěšnost zálohovacích úloh, vývoj nákladů vůči rozpočtu s pěti nejdražšími prostředky, doporučení Advisoru (náklady a zabezpečení), tipy na rightsizing (VM s p95 CPU < 10 %).

**8. První vydání:** **Azure** (odpovídá zaměření Integritu na Microsoft a nástrojům pro Graph/Entra; oficiální šablony pokrývají VM, databáze, zálohy i náklady). AWS na vyžádání; GCP v prvním vydání není.

**9. Pracnost:** produktizace Azure **16–24 h** (nabídka Lighthouse, obalová šablona, filtrování rozsahu, položky Health/Advisor, report), AWS **12–20 h**. Nasazení **1–2 h na předplatné/účet**.

**10. Rizika / otevřené body:** throttling API a náklady na metrické API Azure Monitor ve větším měřítku (intervaly držet ≥ 5 min, pomáhá hromadný sběr v šablonách); discovery může vytvořit mnoho hostů → používat filtry podle tagů, aby počty pro fakturaci zůstaly předvídatelné (stejný princip jako discovery VM v MON-VIRT). Překryv s MON-BKP: u zákazníků, kteří mají obě služby, se cloudové zálohovací úlohy reportují v sekci MON-BKP.


### 5.6.15 MON-CONT · Kontejnery a Kubernetes

**0. Položka katalogu**

| Pole | Návrh |
|---|---|
| Český název | Monitoring kontejnerů a Kubernetes |
| Riziko | 🟠 Vysoké (tam, kde v kontejnerech běží produkční aplikace) |
| Jednotka | Docker host / Kubernetes cluster za měsíc |
| Cena | Docker host 200–400 Kč; Kubernetes cluster 1 500–4 000 Kč (podle počtu uzlů) |
| Text pro zákazníka | Sledujeme kontejnerové hosty a clustery Kubernetes: uzly, kontejnery a workloady, které se zastavují nebo opakovaně restartují, limity prostředků a komponenty clusteru. |
| Omezení | Monitoruje platformu, nikoli sledování výkonu aplikací (APM). |

**1. Rozsah:** Docker: daemon, kontejnery (stav, restarty, health status, CPU/paměť), image; Kubernetes: API server, uzly (ready, pressure), pody (crash loopy, pending), deploymenty (dostupné vs. požadované repliky), persistent volumes, komponenty control plane, kubelet.

**2. Mechanismus na verzi 7.0.31:** *Docker by Zabbix agent 2* (oficiální); Kubernetes: oficiální sada šablon *Kubernetes … by HTTP* (uzly, stav clusteru přes kube-state-metrics, API server, controller manager, scheduler, kubelet) nasazená oficiálním Helm chartem Zabbixu (proxy v clusteru + agenti). Spravované clustery (AKS/EKS) se kombinují s MON-CLOUD.

**3. Místo sběru:** agent 2 na Docker hostech → proxy v lokalitě / vstupní proxy; pro Kubernetes Zabbix proxy uvnitř clusteru (Helm) → odchozí spojení do Integritu.

**5. Výchozí triggery:** kontejner neočekávaně skončil / je unhealthy (Průměrná); smyčka restartů > 3 za 15 min (Vysoká); uzel není ready (Vysoká); nedostupné repliky deploymentu (Vysoká); využití PV > 85 % (Průměrná); chyby API serveru (Vysoká).

**8. První vydání:** do prvního vydání **nedoporučujeme**. Poptávka v zákaznické základně MSP zaměřeného na malé a střední firmy bude pravděpodobně malá; Docker hosty nabízet přes MON-SRV + oficiální šablonu na vyžádání a Kubernetes jako projekt (s cenotvorbou MON-CUSTOM), dokud nebudou alespoň 3 zákazníci.

**9. Pracnost:** obalová šablona pro Docker **4–8 h**; Kubernetes **24–40 h** (hodnoty Helm, vzor multi-tenant proxy, ladění šumu). Nasazení Docker **0,25 h na host**, Kubernetes **4–8 h na cluster**.

**10. Otevřené body:** před investicí ověřit, zda zákazníci kontejnery používají.


### 5.6.16 MON-CCTV · Kamerové systémy (CCTV / NVR)

**0. Položka katalogu**

| Pole | Návrh |
|---|---|
| Český název | Monitoring kamerového systému |
| Riziko | 🟠 Vysoké (kamera, která přestala nahrávat, se odhalí až po incidentu, který měla zaznamenat) |
| Jednotka | rekordér (NVR/VMS) / měsíc vč. až 8 kamer; + za každých dalších 8 kamer |
| Cena | 300–600 Kč za rekordér; +150–300 Kč za každých dalších 8 kamer |
| Text pro zákazníka | Kontrolujeme, že jsou vaše kamery online a že rekordér skutečně nahrává a uchovává záznamy po dohodnutý počet dní, a upozorníme vás na vadné disky v rekordéru. |
| Omezení | Záznamy nesledujeme ani nevyhodnocujeme události v obraze; nejde o službu ostrahy ani pult centralizované ochrany. |

**1. Rozsah:** dostupnost kamer; dostupnost video streamu (RTSP); **stav nahrávání** pro každý kanál (nahrává / nenahrává / ztráta videa); zdraví rekordéru (NVR): stav HDD (vadný, neformátovaný, plný), RAID, pokud je, kapacita úložiště; **retence**: nejstarší záznam vs. dohodnutý počet dní (příliš krátká = ztráta důkazů; příliš dlouhá = problém s GDPR); verze firmwaru kamer/NVR (firmware se známými zranitelnostmi je u této třídy zařízení běžný); synchronizace času rekordéru (časová razítka důkazů); port PoE switche napájející kameru (s MON-LAN).

**2. Mechanismus na verzi 7.0.31**

| Platforma | Jak | Oficiálně v release/7.0? |
|---|---|---|
| Kamery Hikvision | ***Hikvision camera by HTTP*** (ISAPI: dostupnost, CPU/paměť, restarty, chyby kanálů, verze) | Ano |
| Hikvision NVR | Šablona Integritu nad ISAPI (`/ISAPI/ContentMgmt/Storage` pro stav HDD, `/ISAPI/ContentMgmt/record/tracks` / stav kanálů) | Vytváří Integrit |
| Dahua | HTTP CGI API (`/cgi-bin/storageDevice.cgi`, `recordManager`) a SNMP, kde je zapnuté | Vytváří Integrit |
| Axis | VAPIX HTTP API, SNMP MIB | Vytváří Integrit |
| Synology Surveillance Station | Web API (seznam a stav kamer, stav nahrávání) + MON-NAS pro hardware | Vytváří Integrit |
| Milestone XProtect / jiné VMS | API VMS nebo export událostí; na vyžádání | Vytváří Integrit |
| UniFi Protect | Neoficiální API — pro produkt nedoporučujeme | Na vyžádání |
| Obecná záložní varianta | ICMP + `net.tcp.service[tcp,,554]` (RTSP) pro každou kameru | Jednoduché |

**Doporučení:** první vydání s **Hikvision** (šablona pro kamery je oficiální; NVR přes ISAPI) plus obecná záložní varianta ICMP/RTSP pro jakoukoli značku. Nejdřív spočítat značky v zákaznické základně.

**3. Místo sběru:** proxy v lokalitě (kamery jsou v izolované VLAN; proxy potřebuje do této VLAN routu jen pro HTTP(S)/RTSP/ICMP — nikoli opačným směrem).

**4. Předpoklady:** API uživatel jen pro čtení na NVR/kamerách (Hikvision „Operator“ / vlastní role jen pro čtení, zapnuté ISAPI); seznam kamer s umístěním; **dohodnutý počet dní retence** pro každou lokalitu (z GDPR posouzení zákazníka); VLAN kamer dostupná z proxy.

**5. Výchozí triggery**

| Trigger | Závažnost | Výchozí hodnota |
|---|---|---|
| Rekordér nedostupný | Vysoká | 5 min |
| HDD rekordéru vadný / chyba / neformátovaný | Vysoká | – |
| Kamera offline | Průměrná | 10 min (závislé na PoE switchi a rekordéru) |
| Kanál nenahrává / ztráta videa | Vysoká | 15 min, s ohledem na plán nahrávání |
| Retence pod dohodnutým počtem dní | Průměrná | nejstarší záznam < `{$CCTV.RETENTION.DAYS}` − 1 |
| Retence nad dohodnutým maximem | Varování | GDPR, report |
| Odchylka času rekordéru | Varování | > 60 s |
| Firmware se známou zranitelností | Průměrná | z mapování KEV/PSIRT v MON-EXPOSURE |

**6. Závislosti:** kamera → port PoE switche / switch → brána lokality; triggery nahrávání kanálů závisí na triggeru rekordéru. Nahrávání jen podle plánu (např. jen při pohybu nebo v noci) → trigger nahrávání se vyhodnocuje vůči makru s plánem.

**7. Report:** dostupnost kamer, výpadky nahrávání po kanálech (hodiny), skutečná vs. dohodnutá retence, zdraví HDD, stav firmwaru.

**8. První vydání:** Hikvision + obecná záložní varianta; jako další Dahua a Synology Surveillance Station.

**9. Pracnost:** produktizace **16–24 h** (šablona Hikvision NVR, logika nahrávání/retence, obalová šablona pro oficiální šablonu kamer, obecná záložní varianta). Nasazení **0,5–1 h na rekordér**.

**10. Rizika / otevřené body:** kamerová zařízení jsou notoricky známé bezpečnostní riziko; přihlašovací údaje pro monitoring musí být jen pro čtení a proxy nesmí propojovat VLAN kamer s ničím dalším. Kamerové systémy často prodávají firmy z oboru zabezpečovací techniky, ne IT → příležitost pro partnerství.


### 5.6.17 MON-PRINT · Tiskárny a multifunkční zařízení

**0. Položka katalogu**

| Pole | Návrh |
|---|---|
| Český název | Monitoring tiskáren a multifunkčních zařízení |
| Riziko | 🟢 Nízké (nepohodlí, jen výjimečně výpadek klíčového procesu; vyšší u tiskáren štítků a v logistice) |
| Jednotka | zařízení / měsíc |
| Cena | 30–80 Kč za zařízení (balíček za lokalitu), nebo v ceně, pokud Integrit dodává spotřební materiál |
| Text pro zákazníka | Sledujeme stav vašich tiskáren a spotřebního materiálu: docházející toner, zaseknutý papír a chyby. Se smlouvou na dodávky spotřebního materiálu můžeme toner objednat dřív, než dojde. Měsíční počty stran za každé zařízení jsou v reportu. |
| Omezení | Bez servisu a oprav; počty stran odpovídají údajům hlášeným zařízením. |

**1. Rozsah:** dostupnost; stav zařízení a chybový stav (zaseknutý papír, otevřená dvířka, došel papír, nutný servis); úroveň spotřebního materiálu pro každou kazetu/válec/odpadní nádobu (%); zásobníky; celkové počítadlo stran (ČB/barevně, pokud je k dispozici) pro měsíční report stran; verze firmwaru.

**2. Mechanismus na verzi 7.0.31:** v release/7.0 **není oficiální šablona pro tiskárny**. Jedna **obecná šablona Integritu nad standardními MIB** pokryje téměř všechny výrobce: Printer-MIB (RFC 3805: `prtMarkerSuppliesLevel`/`prtMarkerSuppliesMaxCapacity` s LLD nad spotřebním materiálem, `prtAlertTable`, `prtMarkerLifeCount`) a HOST-RESOURCES-MIB (`hrPrinterStatus`, bitová maska `hrPrinterDetectedErrorState` dekódovaná v preprocessingu). MIB výrobců (oddělená počítadla ČB/barva) jen tam, kde je to potřeba. SNMPv3 tam, kde je podporováno; mnoho tiskáren umí jen v1/v2c → community jen pro čtení ve VLAN tiskáren.

**3. Místo sběru:** proxy v lokalitě.

**4. Předpoklady:** SNMP zapnuté na zařízeních; seznam zařízení s umístěním; kdo objednává spotřební materiál (zákazník, nebo Integrit).

**5. Výchozí triggery:** spotřební materiál pod 10 % (Varování; Informace, pokud si zákazník objednává sám), prázdný (Průměrná); chybový stav zařízení (zaseknutý papír / nutný servis) > 15 min (Varování); nedostupné (Varování, jen v pracovní době); kritické tiskárny (štítky, logistika) otagované `tier=critical` → Průměrná/Vysoká.

**6. Falešná upozornění:** tiskárny usínají a některé v hlubokém spánku přestanou odpovídat na SNMP → triggery dostupnosti jen v pracovní době a delší `nodata`.

**7. Report:** počty stran za zařízení (měsíční přírůstek), výměny spotřebního materiálu, četnost chyb.

**8. Varianty:** obecná šablona Zabbixu (**doporučeno**, pokud se prodává v balíčku s dalšími službami lokality); fleet nástroje výrobců (HP Web Jetadmin, Kyocera Fleet Services, Konica Minolta, Canon), pokud má zákazník smlouvu na managed print s dodavatelem — pak nezdvojovat.

**9. Pracnost:** produktizace **8–12 h**. Nasazení **0,1–0,25 h na zařízení** (hromadné přidání přes nástroj pro evidenci).

**10. Doporučení:** jako samostatná položka s nízkou prioritou. Prodávat jako součást balíčku „lokalita“, nebo jen tam, kde Integrit dodává spotřební materiál (pak se služba zaplatí sama díky automatickým objednávkám spotřebního materiálu).


# Část 6 · Pracnost, zavedení, rizika a rozhodnutí

Všechny údaje jsou inženýrské hodiny uvedené v rozpětí. Předpokládají zkušeného inženýra pro Zabbix a jednoho výrobce na službu pro první vydání.

## 6.1 Základ platformy (dnes v katalogu chybí)

| Pracovní balík | Hodiny |
|---|---|
| Revize a zabezpečení platformy: HA, TimescaleDB, MFA/SAML, retence, zálohy | 24–40 |
| Model tenantů: skupiny hostů, tagy, pojmenování, RBAC, konvence závažností | 16–24 |
| Evidence zákazníků a nástroj pro onboarding/offboarding (Zabbix API), export pro fakturaci | 40–60 |
| Image proxy a role pro Ansible; skupiny vstupních a externích proxy; WebDriver | 32–56 |
| Zpevnění media typu pro e-mail přes Graph, sada akcí, pravidla omezení šumu | 12–20 |
| Self-monitoring a externí dead-man switch | 6–10 |
| Git repozitář šablon a importní pipeline | 12–20 |
| Nastavení SLA služeb (automaticky z evidence) | 8–16 |
| Framework generátoru reportů vč. sekcí pro pilotní služby | 80–140 |
| Integrace s Plannerem, pilotní verze (webhook → Graph) | 16–24 |
| Dokumentace a runbooky (obsluha NOC, onboarding, provoz proxy) | 24–40 |
| **Základ celkem** | **270–450** |

## 6.2 Produktizace jednotlivých služeb (první výrobce/platforma)

| Služba | Katalog (v1.0/v1.1) | Tato analýza | Hlavní důvod rozdílu |
|---|---|---|---|
| MON-SRV | 12–24 | 24–40 | Plánované úlohy, aktualizace a komponenty event logu jsou vlastní řešení |
| MON-VIRT | 8–20 / platforma | VMware 8–16, Proxmox 8–16, **Hyper-V 24–40** | Pro Hyper-V neexistuje oficiální šablona |
| MON-NAS | 8–24 / řada | 8–24 / řada | – |
| MON-BKP | 16–32 + 6–20 / konektor | 52–76 (datový model + Veeam + e-mailový parser) | Framework e-mailového parseru pokryje dlouhý chvost produktů |
| SRV-RESTORE | 16–40 | 16–40 | – |
| MON-NET | 12–30 / rodina | 16–24 jednorázově + 12–30 / rodina | Logika WAN/failover/VPN nezávislá na výrobci |
| MON-LAN | 12–32 / výrobce | 12–32 / výrobce + 16–32 / Wi-Fi controller | Controllery jsou samostatné integrace |
| MON-UPS | 8–20 / řada | 12–16 celkem | Obecná šablona UPS-MIB pokryje většinu výrobců |
| MON-WEB | 6–12 | 8–12 | – |
| MON-DNS | 8–20 | 16–24 | DNSSEC, zpracování RDAP/WHOIS |
| MON-WP | 12–24 | **40–80** | Vlastní plugin: vývoj, bezpečnostní revize, kanál pro aktualizace |
| MON-WEB-FUNC | 12–30 | 16–24 + 2–8 / scénář | – |
| MON-EPS | 16–40 / platforma | 24–40 / platforma | – |
| MON-M365 | 24–60 | 24–48 | Oficiální šablona 7.0 pokrývá zdraví a využití; licence a hygiena tenantu jsou vlastní řešení |
| MON-VOIP | 16–50 / výrobce | 8–16 kontrola SIP + 16–50 / výrobce | – |
| MON-CUSTOM | 16–32 framework | 24–40 framework | – |
| Sekce reportu pro 11 nepilotních služeb | – | 44–132 | 4–12 h každá |
| **Služby celkem** | **≈ 200–490** | **≈ 395–795** | |

**Celkem za úplný katalog, první vydání:** zhruba **665–1 245 h** (základ plus všechny služby). Rozsah pilotu níže je přibližně **400–640 h** (základ plus šest pilotních služeb).

**Nasazení u zákazníka:** údaje katalogu na zařízení většinou platí a několik z nich může díky nástroji pro evidenci klesnout. V katalogu chybějí dvě položky, které by měly mít cenu:
- **Onboarding lokality** (proxy, závislosti, evidence, kontakty): 2–4 h pro první lokalitu, 1 h pro každou další.
- **Onboarding zákazníka** (nastavení tenantu, nastavení reportu, směrování upozornění, úvodní schůzka): 2–4 h.

## 6.3 Doporučené pořadí zavádění

**Fáze 0: Základ.** Vše z kapitoly 6.1 kromě úplného generátoru reportů (začít jeho frameworkem) a Planneru.

**Fáze 1: Pilot** se 2–3 vstřícnými zákazníky, se sadou pilotních služeb z v1.0 plus částí MON-NET pro bránu:
- MON-WEB, MON-DNS (bez komponenty v lokalitě zákazníka; nejrychlejší přínos)
- MON-SRV (Windows + Linux)
- MON-BKP (konektor na události Veeamu + e-mailový parser pro jeden další produkt)
- MON-UPS (APC + obecná šablona)
- MON-NET *jen brána + WAN*. Je to kořen stromu závislostí, takže bez něj by pilot při výpadcích lokalit generoval záplavy upozornění.
- Po jednom celém měsíci: první měsíční report, revize šumu a poté zapnutí pilotu Planneru.

**Fáze 2: Hloubka infrastruktury.** MON-NET (v plném rozsahu), MON-LAN, MON-NAS, MON-VIRT; Planner pro všechny spravované zákazníky; v případě potřeby přechod na variantu s mezivrstvou.

**Fáze 3: Cloudové a specializované služby.** MON-M365, MON-EPS, MON-WEB-FUNC, MON-VOIP, framework MON-CUSTOM, SRV-RESTORE. MON-WP po rozhodnutí, zda plugin stavět.

**Přibližně v polovině roku 2027:** upgrade na Zabbix 8.0 LTS (delší podpora, novější verze šablon).

## 6.4 Hlavní rizika

| Riziko | Dopad | Opatření |
|---|---|---|
| Šum upozornění v prvních týdnech | Lidé upozornění ignorují; Planner je zahlcen | Závislosti, zpoždění, revize šumu v pilotu před automatizací tiketů |
| Tichá selhání (výpadek proxy, expirovaný token pro Graph, výpadek Zabbixu) | Nezachycené výpadky, nejhorší možný scénář pro monitoringovou službu | Triggery „naposledy viděno“ u proxy, triggery na selhání médií, externí dead-man switch |
| Únik dat mezi tenanty | Zákazník vidí data jiného zákazníka; reputační a právní škoda | Striktní model pojmenování a tagů, skupiny po zákaznících, žádné sdílené mapy, revize před zpřístupněním zákazníkům |
| Komponenty vytvořené Integritem (WP plugin, e-mailový parser, šablony Hyper-V a M365) | Průběžná údržba | Git, testy na uložených vzorcích, vlastník každé komponenty, při migraci na 8.0 přechod na oficiální šablony |
| Limity Planneru (9 000 úkolů / plán, bez sledování SLA) | Proces tiketů se ve větším měřítku rozpadne | Práh závažnosti, automatické dokončování, rotace plánů, mezivrstva, možnost přejít na skutečný service desk |
| Životní cyklus flotily proxy | Mnoho malých linuxových systémů k patchování | Jeden image, Ansible, automatické bezpečnostní aktualizace, verze svázaná se serverem |
| Rozšiřování rozsahu u MON-CUSTOM a MON-WEB-FUNC | Nefakturovatelná práce | Schvalování přes kartu kontroly a fakturace změnových prací |
| Mezery v šablonách (Hyper-V, Synology/QNAP, licence M365, WP) | Dodatečná pracnost vývoje | Přenositelné šablony Integritu; u každého vydání 8.0 kontrolovat nové oficiální šablony |

## 6.5 Potřebná rozhodnutí (souhrn)

**Platforma**
1. Kde poběží centrální platforma a externí proxy (vlastní datacentrum, nebo cloud).
2. Přístup zákazníků do Zabbixu: nikdy, nebo později (v obou případech s tím počítat v návrhu už teď).
3. Umístění evidence zákazníků: seznam v SharePointu, nebo Git.
4. Odsouhlasit upgrade na 8.0 LTS v polovině roku 2027.

**Konektivita**
5. Proxy v lokalitě jako standard plus jednorázový poplatek za onboarding lokality.
6. Hardwarový standard pro lokality bez virtualizace: navrženo mini-PC třídy Intel N100 (3.2.3); zbývá prodej, pronájem, nebo v ceně.

**Alerting a Planner**
7. ~~Jak je dnes Planner uspořádán~~ **Rozhodnuto 15. 10. 2026:** jeden plán, bucket na zákazníka. Zbývá určit vlastníka archivace dokončených úkolů (limit 9 000 na celý plán).
8. Zpracování obnovy: automatické dokončení vs. štítek k ověření; minimální závažnost pro založení úkolu.
9. Zda nespravovaní zákazníci dostanou automatická e-mailová upozornění ze Zabbixu.
10. Řešení mimo pracovní dobu pro `tier=critical` (SMS/telefon, rozpis pohotovostí).

**Reporting**
11. Jeden souhrnný report na zákazníka (doporučeno).
12. Kontrola inženýrem před odesláním, nebo plně automaticky.
13. Přijmout doporučení vlastního generátoru reportů.

**Služby**
14. Výrobci pro první vydání: jakmile bude známo rozložení zákazníků Integritu podle výrobců (virtualizace, zálohování, firewall, switch/Wi-Fi, NAS, ústředna, endpoint security), vybrat pro každou službu jednoho až dva nejčastější. Rozhodne to rychlé spočítání z evidence majetku Integritu.
15. MON-WP: vyvinout plugin Integritu, nebo omezit službu na weby hostované Integritem / existující nástroj pro správu WP.
16. Wi-Fi AP jako samostatná cenová položka.
17. Ponechat „aktualizace OS“ v MON-SRV (doporučeno).


## 6.6 Celkový obraz včetně doplňkových služeb

| Blok | Hodiny (odhad) |
|---|---|
| Základ platformy (6.1) | 270–450 |
| Služby katalogu, první vydání (6.2) | 395–795 |
| Doplňkové služby, všechny tři vlny (5.1) | 450–800 |
| **Vše celkem** | **≈ 1 115–2 045** |
| Jen pilot (základ + šest pilotních služeb) | ≈ 400–640 |

Rozhodnutí k doplňkovým službám (které vlny, balíčky, pozicování spravované bezpečnosti, model hardwaru senzorů, doplňky smluv) jsou uvedena v kapitole 5.5.


# Příloha · Zdroje a poznámky k ověření

**Zdrojové dokumenty (složka Katalog služeb)**
- v1.0: `Katalog_monitoringovych_sluzeb_Integrit.md` a `.docx`
- v1.1: `Katalog_monitoringovych_sluzeb_integrit_v1.1.md`, interní Word `..._interni_v1.1_rozsireny.docx`, zákaznický Word `..._zakaznicky_v1.1_rozsireny.docx`

**Jak byla fakta ověřena**
- Dostupnost šablon Zabbixu: oficiální repozitář `zabbix/zabbix`, větev `release/7.0` (stav k 14. 10. 2026). Integrační stránky na zabbix.com uvádějí minimální verzi nejnovější větve a mohou mylně naznačovat 7.4+.
- Životní cyklus Zabbixu: 7.0 LTS má plnou podporu do 30. 6. 2027, omezenou podporu do 30. 6. 2029; 8.0 LTS je plánována na 4. čtvrtletí 2026 ([Životní cyklus vydání Zabbixu](https://www.zabbix.com/cz/life_cycle_and_release_policy)).
- Nativní OAuth pro e-mailový media type je k dispozici od verze 7.4 ([fórum Zabbix](https://www.zabbix.com/forum/zabbix-help/505536-zabbix-media-type-m365-oauth)).
- Limity Microsoft Planneru ([Microsoft Learn](https://learn.microsoft.com/en-us/planner/planner-limits)) a přístup k Planneru v režimu aplikace s `Tasks.ReadWrite.All` ([přehled oprávnění](https://graphpermissions.merill.net/permission/Tasks.ReadWrite.All.html)).
- Položky označené *(ověřit)* ještě vyžadují laboratorní ověření na verzi 7.0.31.

**Odhady:** všechny ceny a hodiny jsou odhady pro plánování, které je třeba ověřit v pilotu.

**Pracovní konvence:** dokument je udržován jako jeden zdroj v Markdownu s odpovídajícím souborem Word ve složce `Katalog služeb/Analysis` a je psán v češtině.
