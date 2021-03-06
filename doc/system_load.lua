-- system_load
-- @short: Load and parse additional scripts or modules.
-- @inargs: resstr, *dieonfail*
-- @longdescr: The system_load function is used to dynamically parse/load
-- additional .lua files and, optionally, dynamic libraries. The filename
-- extension determines which namespaces that are allowed and how the resource
-- will be loaded and parsed.
--
-- By default, failure to locate, parse or load the specified resource will
-- lead to a terminal state transition. To avoid this behavior, set *dieonfail*
-- to 0 or false and a failing call will just return nil.
--
-- For .lua files, the existing Lua VM will be used to parse and load the
-- specified script from RESOURCE_APPL or SYS_SCRIPT_RESOURCE. To disallow
-- dynamic code execution by using rawresource_ functions and then system_load,
-- map RESOURCE_APPL_TEMP to a different folder than RESOURCE_APPL.
--
-- For .lib files, the extension will be replaced with the implementation
-- defined library extension on the underlying os (typically .so, .dll
-- or .dylib), and the namespace is restricted to RESOURCE_SYS_LIBS.
--
-- @note: Since dynamic library support is an optional engine feature,
-- and can be used to increase the attack surface or circumvent the VM
-- barrier alltogether, it should be used sparringly and only with verified
-- and trusted code.
--
-- @note: The namespace mapping can be changed compile- time by setting
-- CAREFUL_USERMASK and MODULE_USERMASK for the arcan_lua.c source file.
-- @group: system
-- @cfunction: dofile
function main()
#ifdef MAIN
	system_load("test.lua")();
	system_load("test_bad.lua", 0);

-- this part requires that the examples/test_module has been built and
-- is placed in the RESOURCE_SYS_LIBS
	testfun = system_load("test.lib", false);
	if (testfun == nil) then
		warning("couldn't load dynamic library 'test'");
	else
		testfun.test();
	end

#endif

#ifdef ERROR
	system_load("missing")();
#endif
end
