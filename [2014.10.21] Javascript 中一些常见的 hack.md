# Javascript 中一些常见的 hack

## 双波浪号 `~~`

常用于将浮点数转换为整数，比如 `~~11.2`，这个在像素位置处理时很常见。

## 加号 `+`

常用于将字符串转换为数值，比如 `+"11.2"`，常见于 url 里处理字符串数字。

## 双感叹号 `!!`

常用于将对象转换为布尔类型，比如 `!![]`（这个会返回 `true`）。
注意 `[] == true` 这个会返回 `false`。长见于 console 调试判定结果是否为真。

## `||`

常用于设置变量的默认值，比如 `a = b || 'OK'`，不过这个使用容易产生 bug，比如 b 为 0 或则为空字符串 `''` 的时候，需要多加注意是否满足你定义的非默认值。

## `void 0`

和 undefined 一样，只不过在不同的 js 版本中表现更一致。

## `slice`

常常利用这个函数将有 length 属性的 object 转换成 array 对象。比如

```javascript
var list = document.getElementsByName('div');
console.log(list.reverse());
```

代码会报错，因为这里 `list` 不是数组，而是一个类数组对象，`object` 是没有 `reverse` 方法的。可以利用 slice 将其转换成真正的数组：`var arr = [].slice.call(list);`。
也常用于将 `arguments` 对象转换为真正的数组：

```javascript
foo = function () {
    // 兼容 IE 6 的写法。“[].slice.call” 这种写法不行。
    var arr = Array.prototype.slice(arguments);
};
```