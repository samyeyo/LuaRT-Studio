local ui = require "ui"
local zip = require "zip"

local win = ui.Window("Zip file viewer", 250, 300)
local list = ui.List(win, {}, 0, 40, 250, 260)
list.style = "icons"
local button = ui.Button(win, "Open ZIP file", 80)

local zip_archive
local toremove = {}

function button:onClick()
    local file = ui.opendialog("Select a ZIP archive file", false, "ZIP archive files (*.zip)|*.zip")
    if file ~= nil and zip.isvalid(file) then
        list:clear()
        zip_archive = zip.Zip(file, "read")
        for entry, isdir in each(zip_archive) do
            local dir = isdir and "\\" or ""
            list:add(entry):loadicon(entry..dir)
        end
    end
end

function list:onDoubleClick(item)
    local file = zip_archive:extract(item.text, sys.env.Temp)
    sys.cmd('start /WAIT '..file.fullpath)
    toremove[#toremove+1] = file.fullpath
end

win:show()

repeat
    ui.update()
until win.visible == false

for fname in each(toremove) do
    sys.File(fname):remove()
end