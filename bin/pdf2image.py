import sys
from pdf2image import convert_from_path

pdf_input = sys.argv[1]
outprefix = sys.argv[2]

pages = convert_from_path(pdf_input, 500)

for count, page in enumerate(pages):
    page.save(f'{outprefix}_mqc.jpg', 'JPEG')
