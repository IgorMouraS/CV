-- Divide as secoes de nivel 2 em duas colunas.
-- MAIN (coluna larga): Summary, Experience, Projects
-- SIDE (coluna estreita): tudo o resto (Skills, Education & Certifications, ...)
-- A ordem no DOM e sempre MAIN primeiro -> a extracao de texto do PDF
-- sai sequencial e legivel para ATS, independente da posicao visual.

local MAIN = { summary = true, experience = true, projects = true }

local function key(inlines)
  return pandoc.utils.stringify(inlines):lower():gsub("[^a-z]", ""):sub(1, 20)
end

local function is_main(h)
  local k = key(h.content)
  for name in pairs(MAIN) do
    if k:find(name, 1, true) then return true end
  end
  return false
end

local function contact_block(meta)
  local function m(f) return meta[f] and pandoc.utils.stringify(meta[f]) or nil end
  local pin  = '<svg viewBox="0 0 24 24"><path d="M12 2a7 7 0 0 1 7 7c0 5-7 13-7 13S5 14 5 9a7 7 0 0 1 7-7z"/><circle cx="12" cy="9" r="2.5"/></svg>'
  local mail = '<svg viewBox="0 0 24 24"><rect x="2" y="5" width="20" height="14" rx="2"/><path d="M2.5 7 12 14l9.5-7"/></svg>'
  local ph   = '<svg viewBox="0 0 24 24"><rect x="6" y="2" width="12" height="20" rx="2.5"/><path d="M10.5 18.5h3"/></svg>'
  local link = '<svg viewBox="0 0 24 24"><path d="M9.5 14.5 14.5 9.5"/><path d="M12.5 6.5 14 5a4.2 4.2 0 0 1 6 6l-1.5 1.5"/><path d="M11.5 17.5 10 19a4.2 4.2 0 0 1-6-6l1.5-1.5"/></svg>'
  local code = '<svg viewBox="0 0 24 24"><path d="M8.5 6 3 12l5.5 6"/><path d="M15.5 6 21 12l-5.5 6"/></svg>'
  local rows, order = {}, {
    { pin, m 'location' }, { mail, m 'email' }, { ph, m 'phone' },
    { link, m 'linkedin' }, { code, m 'github' },
  }
  for _, r in ipairs(order) do
    if r[2] then rows[#rows + 1] = '<li>' .. r[1] .. '<span>' .. r[2] .. '</span></li>' end
  end
  return pandoc.RawBlock('html',
    '<h2>Contact</h2>\n<ul class="contact">' .. table.concat(rows, '\n') .. '</ul>')
end

function Pandoc(doc)
  local main, side, bucket = {}, {}, main
  for _, b in ipairs(doc.blocks) do
    if b.t == 'Header' and b.level == 2 then
      bucket = is_main(b) and main or side
    end
    table.insert(bucket, b)
  end
  local side_blocks = { contact_block(doc.meta) }
  for _, b in ipairs(side) do table.insert(side_blocks, b) end

  doc.blocks = {
    pandoc.Div(main, pandoc.Attr('', { 'col-main' })),
    pandoc.Div(side_blocks, pandoc.Attr('', { 'col-side' })),
  }
  return doc
end
