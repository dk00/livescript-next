{lstat-sync} = require \fs
{exec-sync} = require \child_process
lstat-sync \node_modules/livescript-next .is-symbolic-link! or
exec-sync 'npm link && npm link livescript-next'
