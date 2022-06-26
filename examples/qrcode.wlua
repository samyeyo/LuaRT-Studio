--
--  luaRT qrcode.lua example
--  Generate a QR code
--  Author: Onyx from https://community.luart.org
--

local net = require "net" 
local ui = require "ui"

local win = ui.Window("QR Code generation example", 490, 240)
local img = ui.Picture(win, "", 170, 60)
local label = ui.Label(win, "Enter the QR Code content :")
local entry = ui.Entry(win, "https://www.luart.org", label.x + label.width + 4, label.y - 4, 200, 22)
local button = ui.Button(win, "Generate QR code !", entry.x + entry.width + 6, entry.y - 1)

function button:onClick()
    -- Generate a QR Code with the free REST API https://goqr.me/, trademark of DENSO WAVE INCORPORATED
    local qrcode = net.Http("https://api.qrserver.com"):get("/v1/create-qr-code/?size=150x150&data="..entry.text)
    img:load(qrcode)
    qrcode:remove()
end

win:show()

repeat
    ui.update()
until win.visible == false