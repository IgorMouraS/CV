# Resume

## Build your resume in Markdown + HTML, then convert it to PDF

I don't use PowerPoint, Canva, or Word to edit my resume. Aside from the bad experience, they make you re-align every single text box every time you change one line.

So I built mine in Markdown. The content lives in a `.md` file, the styling lives in an HTML template, and a small script turns both into a PDF using the Chrome you already have installed.

## Two layouts, one content file

Both scripts read the same `cv.md` — you write once and pick the layout when you export.

| Script | Output | Layout |
| --- | --- | --- |
| `./build.sh` | `resume/cv.pdf` | Single column |
| `./build-2col.sh` | `resume/cv-2col.pdf` | Sidebar (contact, skills, education) + main column (summary, experience, projects) |

## How to run

Install the only dependency:

```bash
brew install pandoc
```

Then run whichever layout you want:

```bash
./build.sh        # -> resume/cv.pdf
./build-2col.sh   # -> resume/cv-2col.pdf
```

## Files

```
cv.md                your content
template.html        single-column styling
template-2col.html   two-column styling
filter-2col.lua      splits sections between the columns
```

## Result

[Single column](./resume/cv.pdf) · [Two columns](./resume/cv-2col.pdf)
