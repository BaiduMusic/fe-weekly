nobone = require 'nobone'

{kit} = nobone

list = kit.fs.readdirSync '.'

list
.filter (el) -> el[0] == '['
.forEach (el, i) ->
	to = el.replace(/\[.+?\]/, "[#{kit.pad(i, 2)}]")

	kit.log el.cyan + ' -> ' + to.cyan

	kit.fs.rename el, to
