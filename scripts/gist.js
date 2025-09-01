'use strict';

hexo.extend.tag.register('gist', function(args) {
  const gistId = args[0];
  // 支持可选的第二个参数作为文件名
  const file = args[1] ? `?file=${args[1]}` : '';
  return `<script src="https://gist.github.com/${gistId}.js${file}"></script>`;
})