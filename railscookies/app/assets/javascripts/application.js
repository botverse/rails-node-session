// This is a manifest file that'll be compiled into application.js, which will include all the files
// listed below.
//
// Any JavaScript/Coffee file within this directory, lib/assets/javascripts, vendor/assets/javascripts,
// or vendor/assets/javascripts of plugins, if any, can be referenced here using a relative path.
//
// It's not advisable to add code directly here, but if you do, it'll appear at the bottom of the
// compiled file.
//
// Read Sprockets README (https://github.com/sstephenson/sprockets#sprockets-directives) for details
// about supported directives.
//
//= require jquery
//= require jquery_ujs
//= require turbolinks
//= require_tree .

_.templateSettings = {
    interpolate: /\{\{\=(.+?)\}\}/g,
    evaluate: /\{\{(.+?)\}\}/g
};

var message;

var socket = io.connect('http://localhost');
socket.on('message', function (data) {
    $('#messages').append(message({
        color: '#0a0',
        author: data.from,
        content: data.content
    }));
});

$(function(){
    message_template = $('#message-template').html();
    if(message_template) message = _.template($('#message-template').html());
    $('#message').submit(function(){
        var form = $(this)
          , input = form.find('#message_message')
          , to = form.find('#message_to')
          ;

        if ( input.val() ) {
            $('#messages').append(message({
                color: '#f00',
                author: 'You',
                content: input.val()
            }));

            socket.emit('message', {
                to: to.val(),
                content: input.val()
            });

            input.val('');
        }

        return false;
    });
});
