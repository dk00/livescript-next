require! preact: {h}

function head {title, icon, styles, scripts}
  h \head,,
    h \title,, title
    h \meta charset: \utf-8
    h \link rel: \icon href: icon
    ...styles.map -> h \link rel: \stylesheet href: it
    ...scripts.map -> h \script src: it

options =
  title: 'Try LiveScript'
  icon: \//livescript.net/images/icon.png
  styles:
    \index.css
    ...
  scripts:
    \//unpkg.com/preact@7.2.0/dist/preact.min.js
    \//unpkg.com/redux@3.6.0/dist/redux.min.js
    \//livescript.net/livescript-1.5.0-min.js
    \//cdnjs.cloudflare.com/ajax/libs/ace/1.2.6/ace.js
    \//unpkg.com/babel-standalone@6.22.1/babel.min.js
    \//unpkg.com/linking@0.0.2/dist/linking.js
    \//unpkg.com/livescript-next@0.0.1/dist/index.js

function render-html
  h \html,, (head options), h \body,,
    h \div id: \root
    h \script type: \text/ls src: \index.ls
    h \script,, "require('livescript').go()"

module.exports = render-html
