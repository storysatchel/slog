# Humanity's Slice of the Galaxy: Conlangs

This repository contains constructed languages (conlangs) for the *Humanity's Slice of the Galaxy* setting, set in the year 2750. 

The languages are built and managed using the [Audition](https://github.com/gavmor/audition) conlang build tool. 

> **Note for AI Agents:** Please read [AGENTS.md](AGENTS.md) for strict instructions on the translation workflow and directory structures.

## Developed Languages
* **Kisangani Basic** (`/kisangani`): The official language of the Federated States of Kisangani. It is a Bantu-inspired, agglutinative language featuring a robust noun-class system and intensive verbal extensions, designed to culturally resurrect the African historiography of its founders and describe their harsh oceanic planetary environment.

## Upcoming Languages
* Sperosi
* Kubileyan
* Eridian Basic
* Aurelian Basic
* Ulanüuran, Salusan, Aglaean, Retinalian, Scipian, Dajiaoan, Twinworlder
* Remuan Legation (Naming Conventions)

## Usage
To generate the translations from the `.au` templates, run the Audition binary on the target language directory. For example:
```bash
./au -C kisangani
```
