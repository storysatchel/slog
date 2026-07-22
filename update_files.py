import os

files_to_update = {
    "edict_svikiro.md.au": """> **__medium#PL is human#PL.__ __medium#PL interpret#PRES#SP2PL archive#PL of_ma ancestor#PL.__**
> 
> **__medium#PL guide#PRES#SP2PL#EVID state with wisdom of_i ancestor#PL.__ __wealth of_u ocean is currency.__**
""",
    "great_enclosure_plaque.md.au": """> **__take#REV#FUT#SP1PL stone#PL ancestor#PL.__**
> **__learn#CAUS#REV#FUT#SP1PL lie thief#PL.__**
> **__this house great.__ __outsider#PL north build#NEG#PAST#INF, hand#PL shona build#PAST#INF.__ __see#INF engineering of ancestor#PL indigenous.__**
> **__century#PL, exploiter#PL dictate#PAST#INF ruin#PL subjugation.__ __citizen#PL resurrect#PRES#SP1PL truth this: ship#PL come#NEG#PAST#INF, person#PL build#PAST#INF monument#PL stone#CL14.__ __truth carve granite; legacy endure#INF, state mwene mutapa inherit#PRES#INTENS.__**
""",
    "altair_trade_protocols.md.au": """> **__sovereignty atmosphere tribute__**
> 
> **1. __trajectory__**
> __law state kisangani, ship#PL solar enter#NEG#INF atmosphere. trade habitat#PL station#LOC16 sika.__
> 
> **2. __violation__**
> __violation trajectory pilot result#INF revocation deepspace#LOC17. ship#PL lockdown jurisdiction KFN.__
> 
> **3. __tribute tariff__**
> __exploiter#PL enter#NEG#INF ocean altair. trade, exploiter#PL result#INF tribute judge#PL.__
""",
    "aquaculture_addendum.md.au": """> **__field#PL of_i water hang#PRES#SP9 hull#LOC16.__ __citizen#PL harvest#FUT#SP2PL kelp of_u ocean, ili feed#INF habitat#PL, ili generate#INF wealth of_u solar.__**
>
> **__engineering of_i hull mimic#PRES#SP9 roots of_i mangrove, ili generate#INF ocean calm habitat#LOC16.__ __farmer#PL sail#PRES#SP2PL mtumbwi_pl forest#LOC18 of_u kelp.__**
""",
    "habitat_charters.md.au": """> **__habitat float#PRES#SP3 exceed#NEG#INF hectare.__ __engineering of_i hull dictate#PRES#SP9 limit of_ki house#PL thirty in quarter hectare, ili survive#INF squall#PL of_n ocean.__**
> 
> **__person request#PRES#SP1 meter ten of_n house.__ __build#FUT#SP1PL monument#PL of_ma ancestor#PL water#LOC16.__ __citizen#PL share#FUT#SP1PL wealth of_u space.__**
""",
    "mbizi_enforcement.md.au": """> **__exploiter#PL request#PRES#SP2PL water of_ma ocean.__ __exploiter#PL enter#FUT#SP2PL#NEG_IND atmosphere.__ __weigh#INTENS#FUT#SP1PL energy of_n solar, weigh#INTENS#FUT#SP1PL life of_ma kisangani, station#LOC16 sika.__**
>
> **__law of_n kisangani dictate#PRES#SP10.__ __pay tribute, or return deepspace#LOC17.__ __wealth of_u altair belong#PRES#SP14 citizen#PL.__**
""",
    "treaty_sika.md.au": """**__state of_ki kisangani dictate#PRES border law.__ __ship#PL of_i solar enter#NEG_IND#FUT space of_u sika with culture of_i solar.__** 
**__healer#PL protect#PRES#INTENS#EVID this treaty.__ __violation result#PRES#INTENS warrior#PL or missile#PL.__**
""",
    "pedagogical_charter.md.au": """> **__academy#PL teach#PRES#SP8 history of_i kisangani.__ __student#PL learn#PRES#SP2PL language of_u ancestor#PL.__**
> 
> **__reject#FUT#SP1PL#INTENS education of_i solar.__ __education of_i solar is bomb of_i culture.__ __protect#FUT#SP1PL mind#PL of_n citizen#PL.__**
""",
    "oath_nanga.md.au": """> **__healer#PL heal#PRES#SP2PL worker#PL with interconnectedness.__ __modify#PRES#SP1PL#EVID nature with wisdom of_i creator.__**
> 
> **__healer#PL reject#PRES#SP2PL#INTENS greed of_ma solar.__ __life of_ma ocean is interconnectedness.__**
"""
}

directory = "/home/user/Documents/SLOG/src/kisangani/diagetic_samples"

for filename, content in files_to_update.items():
    path = os.path.join(directory, filename)
    with open(path, "w") as f:
        f.write(content)

print("Updates completed.")
