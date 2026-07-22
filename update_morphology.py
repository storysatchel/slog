import yaml
import sys

with open("src/kisangani/morphology.yaml", "r") as f:
    morph = yaml.safe_load(f)

inflections = morph.setdefault("inflections", {})

# Add Noun Classes
inflections["CL1"] = [["^", "mu"]]
inflections["CL2"] = [["^", "va"]]
inflections["CL4"] = [["^", "mi"]]
inflections["CL5"] = [["^", "ri"]]
inflections["CL6"] = [["^", "ma"]]
inflections["CL8"] = [["^", "zvi"]]
inflections["CL9"] = [["^([aeiou].*)$", "ny$1"], ["^", "n"]]
inflections["CL10"] = [["^", "dz"]]
inflections["CL11"] = [["^", "ru"]]
inflections["CL15"] = [["^", "ku"]]

# Add Assocs based on classes extracted
inflections["ASSOC"] = [["^", "a"]]
inflections["CL9.ASSOC"] = [["^", "ya"]]
inflections["CL10.ASSOC"] = [["^", "dza"]]
inflections["CL2.ASSOC"] = [["^", "va"]]
inflections["CL4.ASSOC"] = [["^", "ya"]]
inflections["CL5.ASSOC"] = [["^", "ra"]]
inflections["CL7.ASSOC"] = [["^", "cha"]]
inflections["CL15.ASSOC"] = [["^", "kwa"]]

# Add DEM and POSS
inflections["DEM"] = [["^", "ino"]]  # generic
inflections["POSS"] = [["^", "angu"]] # generic

# Verbal Extensions
inflections["APPL"] = [
    ["([aiu][^aeiou]*)a$", "$1ira"],
    ["([eo][^aeiou]*)a$", "$1era"],
    ["a$", "ira"],
    ["$", "ira"] # for english placeholder roots
]
inflections["FV"] = [
    ["a$", "a"],
    ["$", "a"] # append 'a' for english roots
]
inflections["IMP"] = [
    ["$", ""] # bare stem
]
inflections["PROG"] = [
    ["^", "no"]
]

# Pronouns/Subjects
inflections["1SG"] = [["^", "ndi"]]
inflections["2SG"] = [["^", "u"]]
inflections["1PL"] = [["^", "ti"]]
inflections["1PL.SUBJ"] = [["^", "ti"]]
inflections["3PL.SUBJ"] = [["^", "va"]]

# Prepositions
inflections["PREP"] = [["^", "pa"]] # default to locative Class 16 pa-

# Save back
class MyDumper(yaml.Dumper):
    def increase_indent(self, flow=False, indentless=False):
        return super(MyDumper, self).increase_indent(flow, False)

with open("src/kisangani/morphology.yaml", "w") as f:
    yaml.dump(morph, f, Dumper=MyDumper, default_flow_style=False, sort_keys=False)
