-- test config

test_case = require('test_case')
qiniu_conf = require('conf')

qiniu_conf.ACCESS_KEY = 'iN7NgwM31j4-BZacMjPrOQBs34UG1maYCAQmhdCV'
qiniu_conf.SECRET_KEY = '6QTOr2Jg1gcZEWDQXKOGZh5PziC2MCV5KsntT70j'
qiniu_conf.UP_HOST = 'http://up.qbox.me'
qiniu_conf.RS_HOST = 'http://rs.qbox.me'

test_path = './testdata/logo.png'
