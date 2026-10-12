#!/usr/bin/env python3
"""PDF page/text/font/bounds checks; visual inspection is recorded separately."""
import hashlib,json,re,subprocess,xml.etree.ElementTree as ET
from pathlib import Path
ROOT=Path(__file__).resolve().parents[1];PDF=ROOT/'report.pdf';OUT=ROOT/'verification/phase4'
info=subprocess.check_output(['pdfinfo',str(PDF)],text=True)
if not re.search(r'^Pages:\s+5$',info,re.M):raise RuntimeError('Expected exactly five pages')
text=subprocess.check_output(['pdftotext','-layout',str(PDF),'-'],text=True)
for term in ['Boar Victor','Domeniu și importanța timpului','Decizii de modelare','Protocol de scriere','Dificultăți și încercări','Concluzii','EXPLAIN','împrumuturi','cunoașterii','păstrează','→','∞']:
    if term not in text:raise RuntimeError('PDF text/glyph missing '+term)
for n in range(9):
    if 'Q'+str(n) not in text:raise RuntimeError('Question missing')
if '\ufffd' in text:raise RuntimeError('Unicode replacement character found')
fonts=subprocess.check_output(['pdffonts',str(PDF)],text=True)
rows=fonts.splitlines()[2:]
if not rows or any('yes' not in line for line in rows):raise RuntimeError('Embedded fonts missing')
bbox=subprocess.check_output(['pdftotext','-bbox',str(PDF),'-'],text=True)
root=ET.fromstring(bbox);ns={'x':'http://www.w3.org/1999/xhtml'}
issues=[]
for pageno,page in enumerate(root.findall('.//x:page',ns),1):
    width=float(page.attrib['width']);height=float(page.attrib['height'])
    if abs(width-595.276)>1 or abs(height-841.89)>1:raise RuntimeError('Not A4')
    for word in page.findall('.//x:word',ns):
        if float(word.attrib['xMin'])<31 or float(word.attrib['xMax'])>width-31 or float(word.attrib['yMin'])<20 or float(word.attrib['yMax'])>height-10:
            issues.append({'page':pageno,'word':word.text,'bounds':word.attrib})
if issues:raise RuntimeError('Text outside expected margins: '+repr(issues[:10]))
(OUT/'report_text.txt').write_text(text)
(OUT/'pdf_checks.json').write_text(json.dumps({'pages':5,'a4':True,'all_five_sections':True,'q0_q8':True,'diacritics_and_symbols':True,'embedded_fonts':True,'text_bounds_pass':True,'sha256':hashlib.sha256(PDF.read_bytes()).hexdigest(),'visual_inspection':'All five rendered pages inspected by the assistant; record in phase4_summary.md','pdfinfo':info,'fonts':fonts},ensure_ascii=False,indent=2)+'\n')
print('PASS PDF: 5 A4 pages, sections/Q0–Q8, diacritics/arrows/infinity, fonts, margins')
