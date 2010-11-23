
/*!
 * Ext JS Connect
 * Copyright(c) 2010 Sencha Inc.
 * MIT Licensed
 */

/**
 * Module dependencies.
 */

var queryString = require('querystring');

/**
 * Extract the mime type from the given request's
 * _Content-Type_ header.
 *
 * @param {IncomingMessage} req
 * @return {String}
 * @api private
 */

function mime(req) {
    var str = req.headers['content-type'] || '';
    return str.split(';')[0];
}

/**
 * Decode request bodies.
 *
 * @return {Function}
 * @api public
 */

var util = require('util')

exports = module.exports = function bodyDecoder(){
    return function bodyDecoder(req, res, next) {
        var decoder = exports.decode[mime(req)];
        util.debug("mime="+mime(req)+",body="+util.inspect(req.body)+",length="+util.inspect(req.headers['content-length']));
        if (decoder && !req.body && req.headers['content-length']) {
            var data = '';
            req.setEncoding('utf8');
            req.addListener('data', function(chunk) { data += chunk; });
            req.addListener('end', function() {
                req.rawBody = data;
                try {
                    req.body = data
                        ? decoder(data)
                        : {};
                } catch (err) {
                    return next(err);
                }
                next();
            });
        } else {
            next();
        }
    }
};

/**
 * Supported decoders.
 *
 * - application/x-www-form-urlencoded
 * - application/json
 */

exports.decode = {
    'application/x-www-form-urlencoded': queryString.parse,
    'application/json': JSON.parse
};
