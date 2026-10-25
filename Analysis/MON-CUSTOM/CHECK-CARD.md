# Karta kontroly MON-CUSTOM

Vyplňuje se **před** vytvořením kontroly (návrh 4.16). Bez vyplněné a odsouhlasené karty se kontrola nestaví.
Karta se stává součástí zákaznické dokumentace.

| Pole | Vyplnit |
|---|---|
| Zákazník / ID karty | `<CUST>-CUSTOM-<nn>` |
| Název kontroly | |
| Obchodní účel (proč to zákazník potřebuje) | |
| Vlastník na straně zákazníka (jméno, kontakt) | |
| Vlastník v Integritu | |
| Vzor kontroly | Job · File · Log · Process · HTTP · TCP · jiné (popsat) |
| Signály (co přesně se měří: soubor, URL, název úlohy, proces, log + regex) | |
| Plán / časové okno (kdy má úloha běžet, do kdy musí být hotovo) | |
| Očekávaný výsledek (co je „v pořádku“) | |
| Prahy (max. stáří, min. velikost, počet chyb, doba běhu) | |
| Závažnost (výchozí ze šablony, nebo jiná – zdůvodnit) | |
| Kdo dostává upozornění (bez správy: kontakt zákazníka / se správou: tiket Integrit) | |
| Runbook: co má řešitel udělat | |
| Závislosti (na kterém serveru / službě závisí; např. MON-SRV host) | |
| Reporting ano / ne | |
| Cenová jednotka (kontrola / měsíc) | |
| Údržba (kdo hlásí změny aplikace, které mohou kontrolu rozbít) | |
| Schváleno zákazníkem (datum, jméno) | |

## Zápis do Zabbixu (vyplní technik)

| Vzor | Hostitel | Makro a záznam |
|---|---|---|
| Job | server, kde úloha běží (nebo libovolný host zákazníka) | `{$INT.CUSTOM.JOBS}` += `název\|max-stáří` |
| File | server se souborem | `{$INT.CUSTOM.FILES}` += `štítek\|cesta\|max-stáří\|min-bajtů` |
| Log | server s logem | `{$INT.CUSTOM.LOGS}` += `štítek\|cesta\|regex\|počet` |
| Process | server | `{$INT.CUSTOM.PROCS}` += `štítek\|proces\|min-počet` |
| HTTP | host aplikace (externí nebo lokální proxy) | `{$INT.CUSTOM.URLS}` += `štítek\|url\|regex-těla` |
| TCP | host aplikace | `{$INT.CUSTOM.PORTS}` += `štítek\|host\|port` |

Záznamy oddělovat středníkem `;`, pole svislítkem `|`. Svislítko uvnitř regexu se píše `\|`.
