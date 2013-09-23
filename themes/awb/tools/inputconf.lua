--
-- Keyboard input here is similar to the more simple keyconf.lua
-- It uses the same translation mechanism from table to identity string
-- but uses the awbwman* class of functions to build the UI etc. functions 
--

--
-- fill tbl with PLAYERpc_AXISac   = analog:0:0:none
--          with PLAYERpc_BUTTONbc = translated:0:0:none
--          with PLAYERpc_other
--

local function splits(instr, delim)
	local res = {};
	local strt = 1;
	local delim_pos, delim_stp = string.find(instr, delim, strt);
	
	while delim_pos do
		table.insert(res, string.sub(instr, strt, delim_pos-1));
		strt = delim_stp + 1;
		delim_pos, delim_stp = string.find(instr, delim, strt);
	end
	
	table.insert(res, string.sub(instr, strt));
	return res;
end

local function keyconf_idtotbl(self, idstr)
	local res = self.table[ idstr ];
	if (res == nil) then return nil; end
	
	restbl = splits(res, ":");
	if (restbl[1] == "digital") then
		restbl.kind = "digital";
		restbl.devid = tonumber(restbl[2]);
		restbl.subid = tonumber(restbl[3]);
		restbl.source = restbl[4];
		restbl.active = false;
		
	elseif (restbl[1] == "translated") then
		restbl.kind = "digital";
		restbl.translated = true;
		restbl.devid = tonumber(restbl[2]);
		restbl.keysym = tonumber(restbl[3]);
		restbl.modifiers = restbl[4] == nil and 0 or tonumber(restbl[4]);
		restbl.active = false;
		
	elseif (restbl[1] == "analog") then
		restbl.kind = "analog";
		restbl.devid = tonumber(restbl[2]);
		restbl.subid = tonumber(restbl[3]);
		restbl.source = restbl[4];
	else
		restbl = nil;
	end
	
	return restbl;
end

local function keyconf_tbltoid(self, itbl)
	if (itbl.kind == "analog") then
		return string.format("analog:%d:%d:%s", 
			itbl.devid, itbl.subid, itbl.source);
	end

	if itbl.translated then
		if self.ignore_modifiers then
			return string.format("translated:%d:%s:0", 
				itbl.devid, itbl.keysym);
		else
			return string.format("translated:%d:%d:%s", 
				itbl.devid, itbl.keysym, itbl.modifiers);
		end
	else
		return string.format("digital:%d:%d:%s",
			itbl.devid, itbl.subid, itbl.source);
	end
end

--
-- Try and reuse as much of scripts/keyconf.lua
-- as possible
--
local function set_tblfun(dst)
	dst.id = keyconf_tbltoid;
	dst.idtotbl = keyconf_idtotbl;
	dst.ignore_modifiers = true;
end

local function pop_deftbl(tbl, pc, bc, ac, other)
	for i=1,pc do
		for j=1,bc do 
			tbl["PLAYER" .. tostring(i) .. "_BUTTON" ..tostring(j)] = 
				"translated:0:0:none";
		end

		tbl["PLAYER" .. tostring(i) .. "_UP"]    = "translated:0:0:none";
		tbl["PLAYER" .. tostring(i) .. "_DOWN"]  = "translated:0:0:none";
		tbl["PLAYER" .. tostring(i) .. "_LEFT"]  = "translated:0:0:none";
		tbl["PLAYER" .. tostring(i) .. "_RIGHT"] = "translated:0:0:none";

		for j=1,ac do
			tbl["PLAYER" .. tostring(i) .. "_AXIS" .. tostring(j)] = 
				"analog:0:0:none";
		end

		for k,v in pairs(other) do
			tbl["PLAYER" .. tostring(i) .. "_" .. v] = 
				"translated:0:0:none";
		end
	end
end

--
-- Translation functions just copied from keyconf,
-- and configurations generated here should be valid against
-- other scripts using keysym.lua
--
local function keyconf_buildtable(self, label, state)
-- matching label? else early out.
	local matchtbl = self:idtotbl(label);

	if (matchtbl == nil) then return nil; end
	
-- if we don't get a table from an input event, we build a small empty table,
-- with the expr-eval of state as basis 
	local worktbl = {};

	if (type(state) ~= "table") then
		worktbl.kind = "digital";
		worktbl.active = state and true or false;
	else
		worktbl = state;
	end

-- safety check, analog must be mapped to analog 
-- (translated is a subtype of digital so that can be reused)
	if (worktbl.kind == "analog" and matchtbl.kind ~= "analog") then
		return nil; 
	end
	
-- impose state / data values from the worktable unto the matchtbl
	if (matchtbl.kind == "digital") then
		matchtbl.active = worktbl.active;
		worktbl = matchtbl;
	else
-- for analog, swap the device/axis IDs and keep the samples
		worktbl.devid = matchtbl.devid;
		worktbl.subid = matchtbl.subid;
	end

	worktbl.label = label;
	return worktbl;
end

-- return the symstr that match inputtable, or nil.
local function keyconf_match(self, input, label)
	if (input == nil) then
		return nil;
	end

-- used for overrides à networked remotes etc.
	if (input.external) then
		kv = {};
		table.insert(kv, input.label);
		return kv;
	end

	if (type(input) == "table") then
		kv = self.table[ self:id(input) ];
	else
		kv = self.table[ input ];
	end

-- with a label set, we expect a boolean result
-- otherwise the actual matchresult will be returned
	if label ~= nil and kv ~= nil then
		if type(kv) == "table" then
			for i=1, #kv do
				if kv[i] == label then return true; end
			end
		else
			return kv == label;
		end
		
		return false;
	end

	return kv;
end

local function insert_unique(tbl, key)
	for key, val in ipairs(tbl) do
		if val == key then
			return;
		end
	end
	
	table.insert(tbl, key);
end

local function input_anal(edittbl)
	print("configure analog");
end

local function input_dig(edittbl)
	local cfg = awbwman_cfg();

	local btntbl = {
		{
			caption = cfg.defrndfun("Save"),
			trigger = function(owner)
				edittbl.parent.table[edittbl.name] = owner.lastid;
				edittbl.parent:update_list();
				edittbl.parent.wnd:force_update();
			end,
		},
		{
			caption = cfg.defrndfun("Cancel"),
			trigger = function(owner) end
		}
	};
		
	local msg = cfg.defrndfun( string.format("Press a button for [%s]\\n\\r\t%s",
		edittbl.name, edittbl.bind) );

	local props = image_surface_resolve_properties(edittbl.parent.wnd.canvas.vid);

	local dlg = awbwman_dialog(msg, btntbl, 
		{x = (props.x + 20), y = (props.y + 20), nocenter = true}, false);
	dlg.lastid = edittbl.bind;

	edittbl.parent.wnd:add_cascade(dlg);
	dlg.input = function(self, iotbl)
		local tblstr = edittbl.parent:id(iotbl);
		if (tblstr) then
			dlg.lastid = tblstr;
			local msg = cfg.defrndfun( string.format("Press a button for [%s]\\n\\r\t%s",
			edittbl.name, tblstr) ); 
			if (valid_vid(msg)) then
				dlg:update_caption(msg);
			end
		end
	end

	local real_dest = dlg.destroy;

	dlg.destroy = function(self, speed)
		if (edittbl.parent.wnd.drop_cascade) then
			edittbl.parent.wnd:drop_cascade(dlg);
		end
		real_dest(self, speed);
	end
--	awbwnd_dialog
end

--
-- Just copied from resources/scripts/keyconf.lua
--
local function inputed_saveas(tbl, dstname)
	local k,v = next(tbl);

	zap_resource("keyconfig/" .. dstname);
	open_rawresource("keyconfig/" .. dstname);
	write_rawresource("local keyconf = {};\n");

	for key, value in pairs(tbl) do
		if (type(value) == "table") then
			write_rawresource( "keyconf[\"" .. key .. "\"] = {\"");
			write_rawresource( table.concat(value, "\",\"") .. "\"};\n" );
		else
			write_rawresource( "keyconf[\"" .. key .. "\"] = \"" .. value .. "\";\n" );
		end
	end

   write_rawresource("return keyconf;");
   close_rawresource();
end

local function inputed_editlay(intbl, dstname)
	
	intbl.update_list = function(intbl)
		intbl.list = {};

		for k,v in pairs(intbl.table) do
			if (type(v) == "string") then
				local res = {};
				res.name = k;
				res.bind = v;
				res.parent = intbl;

				local bindstr = "";
				local procv = v;

				res.trigger = (string.sub(v, 1, 6) == "analog") 
					and input_anal or input_dig;
	
				if (v == "analog:0:0:none" or 
					v == "digital:0:0:none" or v == "translated:0:0:none") then
					res.cols = {k, "not bound"};
				else
					res.cols = {k, v};
				end
				table.insert(intbl.list, res);
			end
		end

		table.sort(intbl.list, function(a,b) 
			return string.lower(a.name) < string.lower(b.name); 
		end);
	end

	intbl:update_list();
-- and because *** intbl don't keep track of order, sort list..
	local wnd = awbwman_listwnd(menulbl("Input Editor"), 
		deffont_sz, linespace, {0.5, 0.5}, function(filter, ofs, lim)
			local res = {};
			local ul = ofs + lim;
			for i=ofs, ul do
				table.insert(res, intbl.list[i]);
			end
			return res, #intbl.list;
		end, desktoplbl);

	local cfg = awbwman_cfg();

	wnd.cascade = {};

	wnd.real_destroy = wnd.destroy;
	
	wnd.destroy = function(self, speed)
		local opt = {};
		if (dstname) then
			table.insert(opt, "Update");
		end
		table.insert(opt, "Save As");
		table.insert(opt, "Discard");

		local vid, lines = desktoplbl(table.concat(opt, "\\n\\r"));
	
		local btnhand = function(ind)
			if (opt[ind] == "Save As") then
				local buttontbl = {
					{ caption = desktoplbl("OK"), trigger = function(own)
						inputed_saveas(own.inptbl, own.inputfield.msg .. ".cfg");
					 end }
				};

				local dlg = awbwman_dialog(desktoplbl("Save As:"), buttontbl, {
					input = { w = 100, h = 20, limit = 32, accept = 1 } 
				});
				dlg.inptbl = intbl.table;

			elseif (opt[ind] == "Discard") then
				wnd:real_destroy(speed);

			elseif (opt[ind] == "Update") then
				inputed_saveas(intbl.table, dstname);
				wnd:real_destroy(speed);
			end
		end

		awbwman_popup(vid, lines, btnhand, {ref = wnd.dir.t.left[1].vid}); 
	end

	intbl.wnd = wnd;
	wnd.name = "Input Editor";
end

function inputed_translate(iotbl, cfg)
	if (cfg == nil) then
		return;
	end

	if (iotbl.source == nil) then
		iotbl.source = tostring(iotbl.devid);
	end

	local lbls = keyconf_match(cfg, iotbl);

	if (lbls == nil) then 
		return;
	end

	local res = {};

	for k,v in ipairs(lbls) do
		local tbl = keyconf_buildtable(cfg, v, iotbl);
		table.insert(res, tbl); 
	end

	return res;
end

function inputed_inversetbl(intbl)
	local newtbl = {};

	for k,v in pairs(intbl) do
		newtbl[k] = v;

		if (newtbl[v] == nil) then
			newtbl[v] = {};
		end

		local found = false;
		for h,j in ipairs(newtbl[v]) do
			if (j == k) then 
				found = true;
				break;
			end
		end

		if (not found) then
			table.insert(newtbl[v], k);
		end
	end

	return newtbl;
end

function inputed_getcfg(lbl)
	lbl = "keyconfig/" .. lbl;

	if (resource(lbl)) then
		local res = {};
		res.table = inputed_inversetbl(system_load(lbl)());
		set_tblfun(res);
		return res;
	end

	return nil;
end

--
-- Spawn a window listing layouts, including a "new" will bring up
-- the layout editor, which is a list view of possible labels.
-- doubleclick there brings up the input dialog that samples input
-- (digital or analog) and 
--
function awb_inputed()
	local res = glob_resource("keyconfig/*.cfg", RESOURCE_THEME);	
	local ctable = {};
	set_tblfun(ctable);

	local list = {
		{
			cols    = {"New Layout..."},
			trigger = function(self, wnd)
				wnd:destroy(awbwman_cfg().animspeed);
				local activetbl = {};
				pop_deftbl(activetbl, 4, 8, 6, {"START", "SELECT", "COIN1"});
				ctable.table = activetbl;
				inputed_editlay(ctable);	
			end
		}
	};

	for i,v in ipairs(res) do
		local base, ext = string.extension(v);
		local res = {
			cols = {base}
		};
		res.trigger = function(self, wnd)
			local vid, lines = desktoplbl([[Edit\n\rDelete]]);
			awbwman_popup(vid, lines, function(ind)
				if (ind == 1) then
					wnd:destroy(awbwman_cfg().animspeed);
					ctable.table = system_load("keyconfig/" .. v)();
					if (ctable.table) then
						inputed_editlay(ctable, v); 
					end
				else
					zap_resource("keyconfig/" .. v);
					res = glob_resource("keyconfig/*.cfg", RESOURCE_THEME);
					table.remove(list, ind);
					wnd:force_update();
				end
			end, {});
		end
		table.insert(list, res);
	end

	local wnd = awbwman_listwnd(menulbl("Input Editor"), 
		deffont_sz, linespace, {1.0}, function(filter, ofs, lim)
			local res = {};
			local ul = ofs + lim;
			for i=ofs, ul do
				table.insert(res, list[i]);
			end
			return res, #list;
		end, desktoplbl);
	wnd.name = "Input Editor";
end

function inputed_configlist()
	res = glob_resource("keyconfig/*.cfg", RESOURCE_THEME);
	return res;
end
