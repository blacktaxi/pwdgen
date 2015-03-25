/*
    Bootstrap Flash
    Version: 1.0
    A small lib to display notifications by @vsergeyev
    https://github.com/vsergeyev/bootstrap-flash

    Twitter Bootstrap (http://twitter.github.com/bootstrap).
*/

(function(){
    $(document).ready(function () {
        $("body").prepend('<div class="bootstrap-flash alert hide" style="position:absolute;top:1px;left:25%;width:50%;float:left;z-index:1500;"><a class="close" href="#" onclick="$(this).parent().hide();return false;">&times;</a><p style="margin:0!important"></p></div>');
    });

    this.showflash = function(msg, err) {
        var box = $(".bootstrap-flash");
        console.log(box);
        if (err) {
            box.removeClass("alert-success");
            box.addClass("alert-danger");            
        }
        else {
            box.removeClass("alert-danger");
            box.addClass("alert-success");
        }

        box.find("p").html(msg);
        box.removeClass('hide');
        box.show();
    }

    this.hideflash = function() {
        $(".bootstrap-flash").fadeOut("slow");
    }
}).call(this);