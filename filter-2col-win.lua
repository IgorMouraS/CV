-- Distribui as secoes do curriculo entre a coluna principal e a lateral.
-- MAIN (coluna larga): Summary, Experience, Projects.
-- SIDE (coluna estreita): Contact, Skills, Education e demais secoes.
-- Mantem a coluna principal primeiro no HTML para leitura sequencial.

local MAIN = { summary = true, experience = true, projects = true }

local function key(inlines)
  -- Nao truncar o titulo: "Professional Experience" tem mais de 20 letras
  -- depois de remover espacos, e o truncamento descartava "experience".
  local text = pandoc.utils.stringify(inlines):lower()
  return (text:gsub("[^a-z]", ""))
end

local function is_main(h)
  local k = key(h.content)
  for name in pairs(MAIN) do
    if k:find(name, 1, true) then return true end
  end
  return false
end

local function contact_block(meta)
  local function m(field)
    return meta[field] and pandoc.utils.stringify(meta[field]) or nil
  end

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
    if r[2] and r[2] ~= '' then
      rows[#rows + 1] = '<li>' .. r[1] .. '<span>' .. r[2] .. '</span></li>'
    end
  end

  -- Evita gerar um titulo CONTACT vazio se cv.md nao possui metadados
  -- e impede a duplicacao quando cv.md ja inclui a secao de contato.
  if #rows == 0 then return nil end

  return pandoc.RawBlock('html',
    '<h2>Contact</h2>\n<ul class="contact">' .. table.concat(rows, '\n') .. '</ul>')
end

function Pandoc(doc)
  local main, side = {}, {}
  local bucket = main
  local has_contact_section = false

  for _, block in ipairs(doc.blocks) do
    if block.t == 'Header' and block.level == 2 then
      local heading = key(block.content)
      if heading == 'contact' or heading == 'contacts' then
        has_contact_section = true
      end
      bucket = is_main(block) and main or side
    end
    table.insert(bucket, block)
  end

  local side_blocks = {}
  if not has_contact_section then
    local contact = contact_block(doc.meta)
    if contact then table.insert(side_blocks, contact) end
  end
  for _, block in ipairs(side) do
    table.insert(side_blocks, block)
  end

  doc.blocks = {
    pandoc.Div(main, pandoc.Attr('', { 'col-main' })),
    pandoc.Div(side_blocks, pandoc.Attr('', { 'col-side' })),
  }
  return doc
end
