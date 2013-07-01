-- qiniu conf

qiniu_conf = {
    -- Qiniu hosts' domain names may be changed in the future.
    UP_HOST = 'http://up.qbox.me',
    RS_HOST = 'http://rs.qbox.me',
    IO_HOST = 'http://iovip.qbox.me',
    -- Don't initialize the following constants on client sides.
    ACCESS_KEY = '<Put your ACCESS KEY here>',
    SECRET_KEY = '<Put your SECRET KEY here>'
}

return qiniu_conf
