--[[
图片： img_开头
颜色比值：cmp_开头
颜色多图：mul_开头
识字：ocr_开头
]]
require('path')

findNode = function(selector) return nodeLib.findOne(selector, true) end

findNodes = function(selector)  return nodeLib.findAll(selector, true) end

findByIndex = function (selector) return nodeLib.findByIndex(selector) end

allClick = function (selector) nodeLib.matchAllAndClick(point[selector]) end

findOne = function (target, config)
	if not target then return end
	if type(target) ~= "table" then target = {target} end
	if not config then config = {} end
	config.sim = config.sim or 0.95
	config.rg = config.rg or {0, 0, 0, 0}
	config.imgEnd = config.imgEnd or '.png'
	config.dir = config.dir or 0
	
	if type(config.keyword) == 'string' then config.keyword = {config.keyword} end
	
	-- 截图延迟
	ssleep(capture_interval)
	
	-- 间隔时间查看游戏是否在运行
	if time() - app_is_run > check_game_status_interval then
		if not sAppIsRunning(current_server) then
			log("程序未运行。")
			open(server_pkg_name[current_server])
		end
		if not sAppIsFront(current_server)  then
			open(server_pkg_name[current_server])
		end
		app_is_run = time()
	end
	
	local tar
	releaseCapture()
	keepCapture()
	
	-- 特殊问题讨伐时间到了会弹出
	-- findTap({'cmp_国服派遣任务重新进行'}, {tapInterval = 0, sim = 1})
	if cmpColorEx(point['cmp_国服派遣任务重新进行'], 1) == 1 then ssleep(3) stap('cmp_国服派遣任务重新进行') end
	-- 提交神经网络
	if cmpColorEx(point['cmp_国服Connection'], 1) == 1 then
		releaseCapture()
		wait(function ()
			log('connection..')
			-- 重置wait()超时时间
			if TIMEOUT then
				TIMEOUT = time() + 1000 * TIMEOUTSECOND
			end
			if cmpColorEx(point['cmp_国服Connection'], 1) == 0 then keepCapture() return true end
		end, 1, nil, true)
	end
	
	-- 账号被顶之类的 todo 
		
	for i=1,#target do
		tar = target[i]
		if detail_log_message then log(tar) end
		if tar == "" then return end
		if not debug_disabled then log(tar) end
		if tar:find('img_') then
			ret,x,y = findPicEx(config.rg[1], config.rg[2], config.rg[3], config.rg[4], tar..config.imgEnd, config.sim)
			if x ~= -1 then return {x, y}, tar end
		end
		
		if tar:find('cmp_') then
			local r = cmpColorEx(point[tar], config.sim)
			if r == 1 then
				local p = string.split(point[tar], '|')
				return {tonumber(p[1]), tonumber(p[2])}, tar
			end
		end
		
		if tar:find('mul_') then
			local x=-1 y=-1
			x,y=findMultiColor(config.rg[1], config.rg[2], config.rg[3], config.rg[4], point[tar][1], point[tar][2], config.dir, config.sim)
			if x~=-1 then return {x, y}, tar end
		end
		
		if tar:find('ocr_') then
			local res = ocr(tar)
			if #res > 0 then
				if config.keyword then
					for i=1,#config.keyword do
						for j=1,#res do
							if res[j]['text']:find(config.keyword[i]) then return {res[j]}, tar end
						end
					end
				else
					return res, tar
				end
			end
		end
		
		if tar:find('|') then
			local r = cmpColorEx(tar, config.sim)
			if r == 1 then
				local p = string.split(tar, '|')
				return {tonumber(p[1]), tonumber(p[2])}, tar
			end
		end
		
	end
	
end

findTap = function (target, config)
	local r,w = findOne(target, config)
	if not config then config = {} end
	-- if r then stap(r) return true end
	if r then
		return wait(function ()
			if type(r[1]) == 'table' then
				stap({r[1].l, r[1].t}, config.tapInterval)
			else
				stap(r, config.tapInterval)
			end
			-- if config and config.tapSleepsTime then ssleep(tapSleepsTime) end
			ssleep(other_ssleep_interval)
			if not findOne(target, config) then return w end
		end)
	end
end

findAll = function (target, config)
	if not target then return end
	if type(target) ~= "table" then target = {target} end
	if not config then config = {} end
	config.sim = config.sim or 0.95
	config.rg = config.rg or {0, 0, 0, 0}
	config.imgEnd = config.imgEnd or '.png'
	config.dir = config.dir or 0
	
	-- 检测异常
	-- findOne({})
	
	releaseCapture()
	keepCapture()
	
	local all = {}
	local tar
	-- log(config)
	for i=1,#target do
		tar = target[i]
		
		if tar:find('img_') then
			local res = findPicAllPoint(config.rg[1], config.rg[2], config.rg[3], config.rg[4], tar..config.imgEnd, config.sim)
			if #res > 0 then all[tar] = res end
		end
		
		if tar:find('mul_') then
			local res = findMultiColorAll(config.rg[1], config.rg[2], config.rg[3], config.rg[4], point[tar][1], point[tar][2], config.dir, config.sim)
			if res ~= nil then all[tar] = res end
		end

	end
	
	if not next(all) then return end
	return all
	
end

-- 切割字符串
string.split = function (str, sStr)
	local r = splitStr(str, sStr)
	if r then return r end
end

filterImgSuffix = function (str)
	local res = {}
	for k,v in pairs(str) do
		-- log(k)
		res[string.split(k, '_')[2]] = v
	end
	return res
end

-- 显示多久 持续性，会到timeout才会退出]
longAppearAndTap = function (target, config, pos, timeout)
	local t = time()
	local timeout = timeout or 1.5
	timeout = timeout * 1000
	local r
	wait(function ()
		if pos then stap(pos, 0) end
		r = findOne(target, config)
		if r and time() - t > timeout then return true end
		if not r then t = time() end
	end, .1)
end

-- 消失多久[持续性，会到timeout才会退出]
longDisappearTap = function (target, config, pos, timeout, waitTimeOut)
	local t = time()
	local timeout = timeout or 1.5
	timeout = timeout * 1000
	local r
	wait(function ()
		if pos then stap(pos, 0) end
		r = findOne(target, config)
		if not r and time() - t > timeout then return true end
		if r then t = time() end
	end, .1, waitTimeOut)
end

-- 显示多久 [确保必须是appear页面]
longAppearMomentDisAppear = function (target, config, pos, timeout)
	local t = time()
	local timeout = timeout or 1.5
	timeout = timeout * 1000
	local r
	while true do
		-- if pos then stap(pos, 0) end
		r = findOne(target, config)
		if r and time() - t > timeout then return false end
		if not r then return true end
		ssleep(.1)
	end
end

-- 消失多久[非持续性]
longDisappearMomentTap = function (target, config, pos, timeout)
	local t = time()
	local timeout = timeout or 1.5
	timeout = timeout * 1000
	local r
	while true do
		if pos then stap(pos, 0) end
		r = findOne(target, config)
		if not r and time() - t > timeout then return true end
		if r then return false end
		ssleep(.1)
	end
end

-- 单位秒
ssleep = function (time) time = time or 0 sleep(time * 1000) end

-- 脚本运行时间
appRunningTime = function () return tickCount() end

stap = function (pos, interval, disableTapCheck)
	if not interval then interval = tap_interval end
	-- 解决把挤下线点击了和4点重连接
	-- 防止误点击
	if not disableTapCheck then ssleep(interval) findOne('') end
	-- log(pos)
	if type(pos) == "table" then tap(pos[1], pos[2]) end
	if type(pos) == "string" then local p = string.split(point[pos], '|') tap(tonumber(p[1]), tonumber(p[2])) end
end

-- 识别颜色时间超时
-- 卡在某一处
wait = function (func, interval, TIMEOUT, disableRestartGame)
	interval = interval or wait_interval
	
	if TIMEOUT then
		-- 记录传入的TIMEOUT
		TIMEOUTSECOND = TIMEOUT
		TIMEOUT = time() + 1000 * TIMEOUT
	end
	
	local waitTimeout = time()
	while "q:1352955539" do
		local r = func()
		if r then TIMEOUTSECOND = nil return r end
		ssleep(interval)
		if TIMEOUT and time() + 0 > TIMEOUT then TIMEOUTSECOND = nil TIMEOUT = nil break end
		-- wait 超时可能卡主了
		-- 重启脚本 + 回退到首页
		if not TIMEOUT and not disableRestartGame
									 and time() - waitTimeout > check_game_identify_timeout then
			path.回到主页()
			setStringConfig(scriptStatus, '3')
			reScript()
		end
	end
	
end

-- find operator set position
-- 0 < q1 <= 5 and 0 < q2 <= 10
findOSP = function (queue)
	return point.operatorSet[queue[1]][queue[2]]
end

-- log_history = {}
log = function(...)
	if disable_log then return end
	local arg = {...}
	for _, v in pairs(arg) do
		if type(v) == 'table' then
			print(v)
			for k,v in pairs(v) do print(v) end 
		else
			if logger_display_left_bottom then stoast(v) else print(v) end
		end
	end
	
end

slog = function (msg, level)
	level = level or 3
	local a = os.date('%Y-%m-%d %H:%M:%S')
	msg = a..': '..msg
	console.println(level, msg)
end

setLC = function (name, data)
	if type(data) ~= "string" then data = jsonLib.encode(data) end
	setStringConfig(name, data)
end

getLC = function (name)
	local data = getStringConfig(name)
	if data then jsonLib.decode(data) end
end


sswipe = function (s, e)
	touchDown(1, s[1], s[2])
	ssleep(.05)
	touchMoveEx(1, e[1], e[2], 100)
	touchMoveEx(1, e[1], e[2], 50)
	touchUp(1)
	ssleep(.8)
end

doubleFingerSwiper = function (f, s, e, time)
	touchDown(0, f[1], f[2])
	touchDown(1, s[1], s[2])
	sleep(50)
	touchMoveEx(0, e[1], e[2], time or 150)
	touchMoveEx(1, e[1], e[2], time or 150)
	touchUp(0)
	touchUp(1)
end

onceFingerSwiper = function (f, e, time)
	touchDown(1, f[1], f[2])
	ssleep(.05)
	touchMoveEx(1, e[1], e[2], time or 150)
	ssleep(.1)
	touchUp(1)
	ssleep(1)
end

-- 填写路径滑动
fingerSwiperPath = function (firstPoint, otherPoints, interval)
	
	touchDown(1, firstPoint[1], firstPoint[2])
	ssleep(.05)
	for i=1,#otherPoints do
		touchMoveEx(1, otherPoints[i][1], otherPoints[1][2], interval[i] * 1000 or 1000)
	end
	
	ssleep(1)
	touchUp(1)
	
end

-- 特别处理 控制中枢
-- 有异常，并不是每次结果都是一样的???
swiperWithOperator = function ()
	touchDown(0, 1227, 360)
	touchDown(1, 1227, 360)
	sleep(50)
	touchMoveEx(0, -503, 360, 50)
	touchMoveEx(0, -503, 360, 500)
	touchUp(0)
	touchUp(1)
end

-- https://stackoverflow.com/questions/10460126/how-to-remove-spaces-from-a-string-in-lua
getScreen = function()
	local width, height = getDisplaySize()
	if getDisplayRotate() % 2 == 1 then width, height = height, width end
	return {width = width, height = height}
end
screen = getScreen()
gesture = function(fingers)
	if #fingers == 0 then fingers = {fingers} end
	local gesture = Gesture:new() -- 创建一个手势滑动对象
	for _, finger in pairs(fingers) do
		local path = Path:new()
		for _, point in pairs(finger.point) do path:addPoint(point[1], point[2]) end
		path:setDurTime(finger.duration or 1000)
		path:setStartTime(finger.start or 100)
		gesture:addPath(path)
	end
	gesture:dispatch()
end
Path = {}
function Path:new(o)
	o = o or {startTime = 0, durTime = 0, point = {}}
	setmetatable(o, self)
	self.__index = self
	return o
end
function Path:setStartTime(t) self.startTime = t end
function Path:setDurTime(t) self.durTime = t end
function Path:addPoint(x, y)
	table.insert(self.point, x)
	table.insert(self.point, y)
end
Gesture = {}
function Gesture:new(o)
	o = o or {path = {}}
	setmetatable(o, self)
	self.__index = self
	return o
end
function Gesture:addPath(path) table.insert(self.path, path) end

gestureDispatchOnePath = function(path, id)
	local point = path.point
	if #point < 2 then return end
	local start_time = time()
	local timeline = {}
	local length = 0
	local x, y, px, py
	px = point[1]
	py = point[2]
	sleep(path.startTime)
	for i = 2, #point / 2 do
		x = point[i * 2]
		y = point[i * 2 + 1]
		length = length + math.sqrt((x - px) ^ 2 + (y - py) ^ 2)
		table.insert(timeline, length)
		px, py = x, y
	end
	touchDown(id, point[1], point[2])
	for i = 1,#point do
		x = point[i]
		y = point[i+1]
		-- print("x = "..x)
		-- print("y = "..y)
		timeline[i] = timeline[i] / length * path.durTime
		touchMoveEx(id, x, y, timeline[i])
		if time() - start_time > path.durTime then break end
	end
	sleep(max(0, time() - start_time - path.durTime))
	ssleep(1)
	touchUp(id)
end

function Gesture:dispatch()
	for id, path in pairs(self.path) do
		-- log(71, id, path)
		beginThread(gestureDispatchOnePath, path, id)
	end
end

read = function (path, needDecode)
	local resource = readFile(work_path..path)
	if needDecode then
		resource = jsonLib.decode(resource)
	end
	return resource
end

write = function (path, data, append)
	local tAppend = false
	if append then tAppend = append end
	writeFile(path, jsonLib.encode(data), tAppend)
end

ocr = function(r)
	-- releaseCapture()
	r = point[r]
	r = ocrEx(r[1], r[2], r[3], r[4]) or {}
	return r
end

table.ssort = function (t , parma)
	local res = {}
	if #t == 0 then return res end
	for i=1,#t do
		if i == 1 then
			table.insert(res, t[1])
		else
			-- 7  5  9
			-- 5 7 9
			for e=1,#res do
				if #res == e then table.insert(res, t[i]) end
				if res[e][parma] > t[i][parma] then table.insert(res, e, t[i]) break end
			end
		end
	end
	return res
end

startsWithX = function(x) return function(prefix) return x:startsWith(prefix) end end

string.padStart = function(str, len, char)
	if char == nil then char = " " end
	return string.rep(char, len - #str) .. str
end
string.padEnd = function(str, len, char)
	if char == nil then char = " " end
	return str .. string.rep(char, len - #str)
end
table.diff = function(a, b)
	local ans = {}
	for k, v in pairs(a) do if v ~= b[k] then ans[k] = v end end
	return ans
end
table.index = function(t, idx)
	local ans = {}
	for _, i in pairs(idx) do table.insert(ans, t[i]) end
	return ans
end
table.reduce = function(t, f, a)
	a = a or 0
	for _, c in pairs(t) do a = f(a, c) end
	return a
end
table.sum = function(t)
	local a = 0
	for _, c in pairs(t) do a = a + c end
	return a
end
-- 从t中选出长度为n的所有组合，结果在ans，
table.combination = function(t, n)
	local ans = {}
	local cur = {}
	local k = 1
	combination(t, n, ans, cur, k)
	return ans
end

combination = function(t, n, ans, cur, k)
	-- cur = cur or {}
	-- k = k or 1
	if n == 0 then
		table.insert(ans, shallowCopy(cur))
	elseif k <= #t then
		table.insert(cur, t[k])
		combination(t, n - 1, ans, cur, k + 1)
		cur[#cur] = nil
		combination(t, n, ans, cur, k + 1)
	end
end

table.flatten = function(t)
	local ans = {}
	for _, v in pairs(t) do
		if type(v) == 'table' then
			table.extend(ans, table.flatten(v))
		else
			table.insert(ans, v)
		end
	end
	return ans
end

table.remove_duplicate = function(t)
	local ans = {}
	local visited = {}
	for _, v in pairs(t) do
		if not visited[v] then
			table.insert(ans, v)
			visited[v] = 1
		end
	end
	return ans
end

-- 出现n次的元素
table.appear_times = function(t, times)
	local ans = {}
	local visited = {}
	for _, v in pairs(t) do visited[v] = (visited[v] or 0) + 1 end
	-- log(visited)
	-- exit()
	for k, _ in pairs(visited) do
		if visited[k] == times then table.insert(ans, k) end
	end
	return ans
end

-- table.rotate = function(t, idx)
--   return table.extend(table.slice(t, idx), table.slice(t, 1, idx - 1))
-- end

-- 交
table.intersect = function(a, b)
	local ans = {}
	if #b < #a then a, b = b, a end
	b = table.value2key(b)
	a = table.value2key(a)
	for k, _ in pairs(a) do if b[k] then table.insert(ans, k) end end
	return ans
end

-- 差
table.subtract = function(a, b)
	local ans = {}
	b = table.value2key(b or {})
	a = table.value2key(a or {})
	for k, _ in pairs(a) do if not b[k] then table.insert(ans, k) end end
	return ans
end

table.slice = function(tbl, first, last, step)
	local sliced = {}
	for i = first or 1, last or #tbl, step or 1 do sliced[#sliced + 1] = tbl[i] end
	return sliced
end

-- shallow table
table.contains = function(a, b)
	for k, v in pairs(b) do if a[k] ~= v then return false end end
	return true
end

table.value2key = function(x)
	local ans = {}
	for k, v in pairs(x) do ans[v] = k end
	return ans
end

table.select = function(mask, reference)
	local ans = {}
	for i = 1, #reference do if mask[i] then table.insert(ans, reference[i]) end end
	return ans
end

-- return true if there is an x s.t. f(x) is true
table.any = function(t, f)
	for k, v in pairs(t) do if f(v) then return true end end
end

-- return true if f(x) is all true
table.all = function(t, f)
	for _, v in pairs(t) do if not f(v) then return false end end
	return true
end

table.findv = function(t, f)
	for k, v in pairs(t) do if f(v) then return v end end
end

table.filter = function(t, f)
	local a = {}
	for _, v in pairs(t) do if f(v) then table.insert(a, v) end end
	return a
end

table.div_filter = function(t, f)
	for _, v in pairs(t) do
		local res = f(v)
		if res then return res end
	end
end

table.filterKV = function(t, f)
	local a = {}
	for k, v in pairs(t) do if f(k, v) then a[k] = v end end
	return a
end

table.keys = function(t)
	local a = {}
	t = t or a
	for k, _ in pairs(t) do table.insert(a, k) end
	return a
end

table.values = function(t)
	local a = {}
	t = t or a
	for _, v in pairs(t) do table.insert(a, v) end
	return a
end

-- a,a+1,...b
range = function(a, b, s)
	local t = {}
	if not b and not s then a, b = 1, a end
	s = s or 1
	for i = a, b, s do table.insert(t, i) end
	return t
end

table.includes = function(t, e)
	return table.any(t, function(x) return x == e end)
end

string.includes = function(s, t)
	for _, v in pairs(t) do if s:find(v) then return true end end
end

table.extend = function(t, e)
	for k, v in pairs(e) do table.insert(t, v) end
	return t
end

table.cat = function(t)
	local ans = {}
	for _, v in pairs(t) do for _, n in pairs(v) do table.insert(ans, n) end end
	return ans
end

-- return contains element
table.containsTable = function (old, new)
	local ans = {}
	for i=1,#new do
		if table.includes(old, new[i]) then table.insert(ans, new[i]) end
	end
	return ans
end

--  in = {
--    "A" = {1,4,5,7},
--    "B" = {1,2,5,6},
--    "C" = {3,4,6,7},
--    "D" = {2,3,6,7},
--  }
-- out = { {"A","B"},...}
-- n:key, m:value O(mmn)
table.reverseIndex = function(t)
	local r = {}
	local s = {}
	for k, v in pairs(t) do for k2, v2 in pairs(v) do s[v2] = true end end
	for k, v in pairs(s) do
		r[k] = {}
		for k2, v2 in pairs(t) do
			if table.includes(v2, k) then table.insert(r[k], k2) end
		end
	end
	for k, v in pairs(r) do table.sort(v) end
	return r
end

table.find = function(t, f) for k, v in pairs(t) do if f(v) then return k end end end

table.shuffle = function(tbl)
	for i = #tbl, 2, -1 do
		local j = math.random(i)
		tbl[i], tbl[j] = tbl[j], tbl[i]
	end
	return tbl
end

-- one depth compare, and key-value pairs all same
table.equal = function(a, b)
	if type(a) ~= 'table' or type(b) ~= 'table' then return end
	
	if #a ~= #b then return end
	if #a == 0 and #table.keys(a) ~= #table.keys(b) then return end
	
	for k, v in pairs(a) do if v ~= b[k] then return end end
	return true
end

-- one depth compare, and key all same
table.equalKey = function(a, b)
	if type(a) ~= 'table' or type(b) ~= 'table' then return end
	
	if #a ~= #b then return end
	if #a == 0 and #table.keys(a) ~= #table.keys(b) then return end
	
	for k, _ in pairs(a) do if b[k] == nil then return end end
	return true
end

map = function(...)
	local a = {...}
	local n = select("#", ...)
	local r = {}
	local f, x = a[1], a[2]
	local p, ur
	if n < 2 then return r end
	if n == 2 then
		n = #x
	elseif n > 2 then
		ur = true
		x = {table.unpack(a, 2, n)}
		n = n - 1
	end
	for i = 1, n do
		p = x[i]
		if type(f) == "function" then
			p = f(p)
		elseif type(f) == "table" then
			p = f[p]
		end
		r[i] = p
	end
	if ur then return table.unpack(r, 1, n) end
	return r
end

table.join = function(t, d)
	t = t or {}
	d = not d and ',' or d
	local a = ''
	for i = 1, #t do
		a = a .. t[i]
		if i ~= #t then a = a .. d end
	end
	return a
end

string.trim = function (s)
	return (s:gsub("^%s*(.-)%s*$", "%1"))
end

shallowCopy = function(x)
	local y = {}
	if x == nil then return y end
	for k, v in pairs(x) do y[k] = v end
	return y
end

max = math.max
min = math.min
math.round = function(x) return math.floor(x + 0.5) end
round = math.round
clip = function(x, minimum, maximum) return min(max(x, minimum), maximum) end

table.findInsert = function (t, n, v)
	if not t[n] then t[n] = {} end
	if type(v) == "table" then
		for i=1,#v do table.insert(t[n], v[i]) end
	else
		table.insert(t[n], v[i])
	end
end

-- 从table中获取随机数
table.randomWithTableIn = function (arr, many)
	local t = {}
	local tempIndex = {}
	local cur
	wait(function ()
		cur = math.ceil(math.random(1, #arr))
		if not table.includes(tempIndex, cur) then table.insert(tempIndex, cur) end
		if #tempIndex == many then return true end
	end, 0)
	for i=1,#tempIndex do table.insert(t, arr[tempIndex[i]]) end
	return t
end

filterImgSuffix = function (t)
	local c = {}
	if type(t) ~= "table" then return t end
	if t[1] then
		for i=1,#t do table.insert(c, splitStr(t[i],"img_")[2]) end
	else
		for _,v in pairs(t) do c[splitStr(_,"img_")[2]] = v end
	end
	return c
end


-- 获取倒数时间
getTimeBase = function (secound)
	return secound + math.floor(time() / 1000)
end

-- 获取相差时间(结束时间， 开始时间)
getTime = function (startTime, isMinus)
	local sec = tonumber(startTime) or 0
	if isMinus then
		sec = startTime - math.floor(time() / 1000)
	end
	local day = math.floor(sec / 60 / 60 / 24)
	local hour = math.floor(sec / 60 / 60 % 24)
	local min = math.floor(sec / 60 % 60)
	sec = sec % 60
	return day.."天"..hour.."时"..min.."分"..sec.."秒"
end

-- 获得所有K
getAllKey = function (originData)
	if not originData then return {} end
	local r = {}
	for _,v in pairs(originData) do table.insert(r, _) end
	if #r > 0 then table.sort(r) end
	return r
end

chineseUnicodeStringMatch = function(a, b)
	local len = min(#a, #b) // 3
	local score = 0
	for i = 1, len do
		if a:sub(i * 3 - 2, i * 3) == b:sub(i * 3 - 2, i * 3) then
			score = score + 1
		end
	end
	return score
end

--获取时间
getDate = function ()
	return os.date('%Y-%m-%d %H:%M:%S')
end

local ISRUN
closeWin = function (w)
	ISRUN = false
	ui.dismiss(w)
end

-- 更新提示
uploadScriptTip = function (data)
	ISRUN = true
	ui.newLayout("更新", 600)
	ui.addTextView("更新","QQGroupTip","QQ交流群：")
	ui.addTextView("更新","QQGroup","741063351")
	ui.setTextColor("QQGroup","#FFFF0000")
	ui.newRow("更新","row2")
	ui.addTextView("更新","messageTip","更新内容：")
	ui.newRow("更新","row1")
	ui.addTextView("更新","message", data)
	ui.newRow("更新","row3")
	ui.addButton("更新","iknow","知道了 10s")
	
	ui.setTextSize("message", 10)
	ui.setTextColor("messageTip","#FFFF730B")
	ui.setTitleBackground("更新","#FFFF0000")
	ui.setFullScreen("iknow")
	ui.show("更新", false)
	ui.setOnClick("iknow","closeWin('更新')")
	
	for i=1,10 do
		if not ISRUN then break end
		ssleep(1)
		ui.setButton("iknow","知道了 "..10-i.."s", -1)
	end
	
	closeWin('更新')
end

-- 更新app
uploadAppTip = function (message)
	ISRUN = true
	ui.newLayout("APP更新", 600)
	-- ui.addTextView("APP更新","message", message)
	ui.newRow("APP更新","row2")
	
	ui.addTextView("APP更新", "down", "https://wwm.lanzouv.com/iNTtJ0at6rfi")
	ui.newRow("APP更新","row3")
	ui.addTextView("APP更新","pass","密码：66")
	ui.newRow("APP更新","row4")
	ui.addButton("APP更新","download","下载")
	
	ui.setTextSize("message", 10)
	ui.setTextSize("down", 10)
	ui.setTextSize("pass", 10)
	ui.setTextColor("messageTip","#FFFF730B")
	ui.setTitleBackground("APP更新","#FF00FF40")
	ui.setFullScreen("download")
	ui.show("APP更新", false)
	ui.setOnClick("download","jumbNewAppWebSite('https://wwm.lanzouv.com/iNTtJ0at6rfi')")
	
	while ISRUN do
		ssleep(1)
	end
end

-- 跳转到最新跟新app网页
jumbNewAppWebSite = function (website)
	i ={};
	-- android 配置的action 选项， 通常和uri 配合使用
	i['action'] = "android.intent.action.VIEW";
	-- uri 通常用作协议跳转
	i['uri'] = website;
	-- data 额外增加的数据
	i['data'] ="";
	-- packageName 通常指 要跳转的包名
	i['packageName'] = "";
	-- classname 通常指 具体要跳转的activity
	i['classname'] = "";
	-- extra 为额外增加的 参数
	i['extra'] = {};
	i['extra']["data"] = "hello";
	runIntent(i)
	closeWin("APP更新")
end

hscale = screen.height / 1080
wscale = screen.width / 1920
minscale = min(hscale, wscale)
maxscale = max(hscale, wscale)

scale = function(x, mode)
	if not mode or mode == 'min' then
		return math.round(x * minscale)
	elseif mode == 'max' then
		return math.round(x * maxscale)
	elseif type(mode) == 'number' then
		return math.round(x * mode)
	end
end

solveCapture = function(server)
	log("滑动验证码")
	ssleep(other_ssleep_interval)
	keepCapture()
	local node = findNode({class = "android.webkit.WebView", package = server})
	if not node then
		log("未发现节点")
		return
	end
	local left, top = node.bounds.l, node.bounds.t
	point.captcha_area = {
	left + scale(240), top + scale(40), left + scale(789), top + scale(481),
	}
	point.captcha_left_area = {
	left + scale(105), top + scale(40), left + scale(196), top + scale(481),
	}
	point.captcha_area_btn = {left + scale(114), top + scale(609)}
	
	local w, h, color
	local i, j, b, g, r
	local best, best_score, best_left, best_right
	local data
	local maxgrad
	local diff1, diff2, y1, y2, y3
	w, h, color = getScreenPixel(table.unpack(point.captcha_area))
	data = {}
	for i = 1, #color do
		b, g, r = colorToRGB(color[i])
		table.extend(data, {r, g, b})
	end
	
	maxgrad = {}
	for i = w + 1, #color do
		y1 = (0.299 * data[i * 3 - 2] + 0.587 * data[i * 3 - 1] + 0.114 *
		data[i * 3])
		y2 =
		(0.299 * data[(i - 2) * 3 - 2] + 0.587 * data[(i - 2) * 3 - 1] + 0.114 *
		data[(i - 2) * 3])
		y3 =
		(0.299 * data[(i - w) * 3 - 2] + 0.587 * data[(i - w) * 3 - 1] + 0.114 *
		data[(i - w) * 3])
		diff1 = y1 - y2
		diff2 = y1 - y3
		maxgrad[i % w] = (maxgrad[i % w] or 0) + max(0, diff1) /
		(1 + math.abs(diff2))
	end
	
	-- local best = {}
	-- for i = 4, #maxgrad do
	--   table.insert(best, {maxgrad[i], i + point.captcha_area[1]})
	-- end
	-- table.sort(best, function(a, b) return a[1] > b[1] end)
	-- log(table.slice(best, 1, 10))
	-- log(point.captcha_area)
	-- exit()
	
	best = 1
	best_score = 0
	for i = 4, #maxgrad do
		if best_score < maxgrad[i] then
			best_score = maxgrad[i]
			best = i
		end
	end
	
	best_right = best + point.captcha_area[1]
	
	w, h, color = getScreenPixel(table.unpack(point.captcha_left_area))
	data = {}
	for i = 1, #color do
		b, g, r = colorToRGB(color[i])
		table.extend(data, {r, g, b})
	end
	maxgrad = {}
	for i = w + 1, #color do
		y1 = (0.299 * data[i * 3 - 2] + 0.587 * data[i * 3 - 1] + 0.114 *
		data[i * 3])
		y2 =
		(0.299 * data[(i - 2) * 3 - 2] + 0.587 * data[(i - 2) * 3 - 1] + 0.114 *
		data[(i - 2) * 3])
		y3 =
		(0.299 * data[(i - w) * 3 - 2] + 0.587 * data[(i - w) * 3 - 1] + 0.114 *
		data[(i - w) * 3])
		diff1 = y1 - y2
		diff2 = y1 - y3
		maxgrad[i % w] = (maxgrad[i % w] or 0) + max(0, -diff1) /
		(1 + math.abs(diff2))
	end
	
	-- local best = {}
	-- for i = 4, #maxgrad do
	--   table.insert(best, {maxgrad[i], i + point.captcha_area[1]})
	-- end
	-- table.sort(best, function(a, b) return a[1] > b[1] end)
	-- log(table.slice(best,1,10))
	-- exit()
	
	best = 1
	best_score = 0
	for i = 4, #maxgrad do
		if best_score < maxgrad[i] then
			best_score = maxgrad[i]
			best = i
		end
	end
	
	best_left = best + point.captcha_left_area[1]
	-- log(3399, best_left, best_right)
	-- exit()
	
	-- log(table.slice(best, 1, 10))
	-- exit()
	-- log(w, h, best, best_score, best + point.captcha_area[1])
	
	-- for i = 1, #maxgrad do log(i, maxgrad[i]) end
	-- log(point.captcha_area)
	--
	local distance = best_right - best_left
	local sx, sy
	sx = point.captcha_area_btn[1]
	sy = point.captcha_area_btn[2]
	local duration = 500
	local finger = {
	point = {
	{sx, sy}, {sx + distance, sy},
	{sx + distance + scale(10), sy - scale(100)},
	{sx + distance + scale(10), sy},
	{sx + distance + scale(10), sy - scale(100)},
	{sx + distance + scale(10), sy},
	{sx + distance - scale(10), sy - scale(100)},
	{sx + distance - scale(10), sy},
	{sx + distance - scale(10), sy - scale(100)},
	{sx + distance - scale(10), sy}, {sx + distance, sy - scale(100)},
	{sx + distance, sy}, {sx + distance, sy - scale(100)},
	{sx + distance, sy}, {sx + distance, sy - scale(100)},
	{sx + distance, sy},
	},
	duration = duration,
	}
	-- log(finger.point[1], finger.point[#finger.point])
	gesture(finger)
	sleep(duration + 300)
	
	releaseCapture()
end

input = function(selector, text)
	if type(text) ~= 'string' then return end
	local node = findNodes(point[selector])
	if not node then return end
	for _, n in pairs(node) do nodeLib.setText(n, text) end
end


stringMather = function (fun, str)
	local str = string.trim(str)
	if #str == 0 then return end
	if fun(str) then return tonumber(str) or str end
end

sFileExist = function (path)
	local path = work_path..path
	return fileExist(path)
end

logger = function (fun, config)
	hideHUD(logger_ID)
	if not fun then return end
	logger_ID = createHUD()
	showHUD(logger_ID, fun(), config[1], config[2], config[3], config[4], config[5], config[6], config[7], config[8], 0, 0, 0, 0, 2)
end

-- serverName: 服务器名称数组(中文名称，非pkgName)
sAppIsRunning = function (serverName)
	if type(serverName) == "string" then serverName = {serverName} end
	for i=1,#serverName do
		if appIsRunning(server_pkg_name[serverName[i]]) then return true, serverName[i] end
	end
end

sAppIsFront = function (appNames)
	local appNames = appNames
	if type(appNames) == "string" then appNames = {appNames} end
	for i=1,#appNames do
		if appIsFront(server_pkg_name[appNames[i]]) then return true, appNames[i] end
	end
end

sStopApp = function (appNames)
	if disable_refresh_tag then exit() end
	local appNames = appNames
	if type(appNames) == "string" then appNames = {appNames} end
	for i=1,#appNames do
		-- log("停止："..appNames[i])
		stopApp(server_pkg_name[appNames[i]])
	end
end

-- 获取当前星期
getCurWeek = function ()
	return uiSetting.week[tonumber(tonumber(os.date("%w")) == 0 and 7 or tonumber(os.date("%w")))]
end

open = function (appid)
	if not appid then appid = "" end
	runApp(appid)
end

stoast = function (message, x, y, messageSize)
	if getDisplayRotate() == 0 then
		toast(message, x or 0, y or 0, messageSize or 12)
	else
		toast(message, x or 0, y or 720, messageSize or 8)
	end
end

exit = function () exitScript() end

reScript = function () restartScript() end

-- 热更
-- 获取字符串的长度（任何单个字符长度都为1）
-- 解决中文长度问题
getStringLength = function(inputstr)
	if not inputstr or type(inputstr) ~= "string" or #inputstr <= 0 then
		return nil
	end
	local length = 0  -- 字符的个数
	local i = 1
	while true do
		local curByte = string.byte(inputstr, i)--根据首字节的大小确定
		local byteCount = 1
		if curByte > 239 then --11110xxx
			byteCount = 4  -- 4字节字符
		elseif curByte > 223 then --1110xxxx
			byteCount = 3  -- 3字节字符
		elseif curByte > 128 then  --110xxxxx
			byteCount = 2  -- 双字节字符
		else
			byteCount = 1  -- 单字节字符
		end
		-- local char = string.sub(inputstr, i, i + byteCount - 1)
		-- print(char)  -- 打印单个字符
		i = i + byteCount
		length = length + 1
		if i > #inputstr then
			break
		end
	end
	return length
end

hotUpdate = function ()
	local path = 'https://gitee.com/boluokk/e7-helper/blob/master/release/'
	-- UI图资源文件
	local staticFileUrl = path.."files"
	-- 脚本文件
	local scriptFileUrl = path.."script"
	
	stoast("正在检查更新...")
	-- local fileMsg = hotUpdateProcess(staticFileUrl, {"filesMD5", getStringConfig("filesMD5")}, ".zip")
	local scriptMsg = hotUpdateProcess(scriptFileUrl, {"scriptMD5", getStringConfig("scriptMD5")}, ".lr")
	-- local m1 = fileMsg and fileMsg.message
	local m2 = scriptMsg
	
	if m1 or m2 then
		local message = ""
		local count = 1
		-- if m1 then message = message..count.."："..m1.."\n" count = count + 1 end
		if m2 then message = message..count.."："..m2 end
		wait(function () toast(message) end, 1, 2)
	end
	
	if scriptMsg then reScript() end
end

-- 第一次初始化
-- md5码不一致
-- md5一致 X
hotUpdateProcess = function (url, validFileMd5, fileSuffix)
	local newAppInfo = shttpGet(url..".lr.md5", true)
	local stringkey = validFileMd5[1]
	if not newAppInfo then log("校验下载异常，请重试") exit() end
	-- 未初始化
	if validFileMd5[2] == "" or validFileMd5[2] ~= newAppInfo then
		stoast("更新中..")
		local fileName, splitFileName = sdownloadFile(url..fileSuffix)
		if fileName then
			resolveZipFile(splitFileName)
			setLC(stringkey, newAppInfo)
			return newAppInfo
		else
			log("文件下载异常，请重试") ssleep(1) exit()
		end
	end
	
	log("无需更新，已经最新版本")
end

-- 成功返回
-- 文件名称、文件名文件类型数组
sdownloadFile = function (url)
	-- update.zip
	local fileName = url:match("[%w_]+%.[%w]+$")
	-- {"update", "zip"}
	local splitFileName = fileName:split(".")
	if downloadFile(url, work_path.."/"..fileName, downloadFileProgressTip) == 0 then return fileName, splitFileName end
end

-- 下载提示
downloadFileProgressTip = function(pos) stoast("下载进度："..pos) end

-- 解压文件
-- fileNameArray：{"update", "zip"}
resolveZipFile = function (fileNameArray)
	local fileName = fileNameArray[1]
	local fileType = fileNameArray[2]
	if fileType == "zip" then -- 解压文件
		if sFileExist("/"..fileName) then sdelfile("/"..fileName) end
		stoast("开始解压文件..")
		unZip(work_path.."/"..fileName.."."..fileType, work_path.."/"..fileName)
		stoast("解压完成")
	elseif fileType == "lr" then -- 重新安装文件
		installLrPkg(work_path.."/"..fileName.."."..fileType)
		stoast("安装脚本文件完成")
	end
end

sdelfile = function (path)
	delfile(work_path..path)
end

shttpGet = function (url, disableDecode)
	local ret, code = httpGet(url)
	if code ~= 200 then return end
	if disableDecode then return ret end
	return jsonLib.decode(ret)
end

-- swip for operator
swipo = function(left, nodelay)
	local duration
	local finger
	local delay
	if left then
		local x1 = scale(600)
		local x2 = scale(10000 / 720 * 1080)
		local y1 = scale(533)
		duration = 400
		finger = {{point = {{x1, y1}, {x2, y1}}, duration = duration}}
		delay = 750
	else
		local x = scale(600)
		local y = scale(533)
		-- local y2 = scale(900)
		local y2 = scale(900)
		local x2 = scale(1681)
		local y3 = scale(900)
		local slids = 50
		local slidd = 200
		local taps = slids + slidd + 150
		local tapd = 200
		local downd = taps + 100
		duration = downd
		finger = {
		{point = {{x, y}, {x, y2}}, start = 0, duration = downd},
		{point = {{x2, y}, {x2, y3}}, start = slids, duration = slidd},
		{point = {{x2, y}, {x2, y}}, start = taps, duration = tapd},
		}
		delay = 250
	end
	log(jsonLib.encode(finger))
	gesture(finger)
	sleep(duration + (nodelay and 0 or delay))
	return nodelay and delay or 0
end


currentAllRunningApp = function (pkgs)
	local ans = {}
	for i=1,#pkgs do if sAppIsFront(pkgs[i]) then table.insert(ans, pkgs[i]) end end
	return ans
end

-- 所有服务器
all_server = getAllKey(server_pkg_name)
-- 提示服务器选择正确是否，仅单账号
-- 选错服务器情况下或者没有下载的情况下
tipCheckServer = function (close)
	local close
	-- 未安装则直接退出
	-- 安装了但是不对则提示
	local apps = getInstalledApk()
	local curPkg = server_pkg_name[current_server]
	if #table.containsTable(apps, {curPkg}) > 0 then return else close = true end
	
	local allSer = table.values(server_pkg_name)
	local exApps = table.containsTable(apps, allSer)
	local runApps = currentAllRunningApp(all_server)
	local msg = ""
	
	for i=1,#exApps do
		local k = getAllKey(table.filterKV(server_pkg_name, function (k, v) if v == exApps[i] then return k end end))
		if i ~= #exApps then
			msg = msg..k[1].."、"
		else
			msg = msg..k[1]
		end
	end
	
	msg = msg.."\n当前运行："
	if #runApps == 0 then msg = msg.."无" end
	for i=1,#runApps do
		local k = getAllKey(table.filterKV(server_pkg_name, function (k, v) if k == runApps[i] then return k end end))
		if i ~= #runApps then
			msg = msg..k[1].."、"
		else
			msg = msg..k[1]
		end
	end
	-- log(exApps)
	wait(function ()
		stoast("当前选择服务器："..current_server.."\n已安装："..msg)
	end, 1, 10)
	
	if close then exit() end
end

--重置状态
resetStatus = function (isMultAcc)
	setStringConfig("scriptStatus", 0)
	if isMultAcc then setStringConfig("curAccount", 0) end
	setStringConfig("taskIndex", 0)
	setStringConfig("rougeIndex", 1)
	setStringConfig("fightCount", 0)
	setStringConfig("SXYSCount", 1)
	setStringConfig("currentWeek", getCurWeek())
end

untilTap = function (target, config)
	wait(function () if findTap(target, config) then return true end end)
end

untilAppear = function (target, config)
	local r1,r2
	wait(function ()
		r1,r2 = findOne(target, config)
		if r1 then return true end 
	end)
	return r1,r2
end

-- 获取竞技场积分
getArenaPoints = function (p)
  local points = ''
  for i in string.gmatch(p, '[0-9]+') do points = points..i end
  return tonumber(points) or 0
end

uuid = function()
	local template ="xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx"
	local d = io.open("/dev/urandom", "r"):read(4)
	math.randomseed(os.time() + d:byte(1) + (d:byte(2) * 256) + (d:byte(3) * 65536) + (d:byte(4) * 4294967296))
	return string.upper(string.gsub(template, "x", function (c)
		local v = (c == "x") and math.random(0, 0xf) or math.random(8, 0xb)
		return string.format("%x", v)
	end))
end