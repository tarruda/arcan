-- render_text
-- @short: Convert a format string to a new video object.
-- @inargs: message, *vspacing*, *tspacing*
-- @outargs: vid, lineheights
-- @longdescr: Render a format string into a texture assigned to a new video object.
-- Return this object along with a table of individual line-heights. The string will
-- be treated internally as UTF8. Vspacing indicates the default padding between lines,
-- and tspacing the horizontal spacing between tabs. Each formatting sequence is initiated
-- with a single backspace, followed with a command code (see table below). Stateful
-- commands (b, i, u) can be negated with a preluding exclamation point.
-- @tblent: t tab
-- @tblent: n newline
-- @tblent: r carriage-return
-- @tblent: u underline
-- @tblent: b bold
-- @tblent: i italic
-- @tblent: ffname,size switch font
-- @tblent: #rrggbb switch font color
-- @tblent: pfname embedd image
-- @tblent: Pfname,w,h embedd image, scale to w*h
-- @group: image
-- @cfunction: arcan_lua_buildstr
-- @exampleappl: tests/interactive/fonttest
-- @related: text_dimensions

