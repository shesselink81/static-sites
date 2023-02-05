$(document).ready(function () {
    init_SubscribeFormValidator();

    $("#btn_subscribe").click(function () {
        var txtEmail = $('#txtSubscribeEmail');
        if ($('#frm_subscribe').valid()) {
            var ajaxRequest = $.ajax({
                url: 'handlers/subscribe.php',
                type: "POST",
                data: { email: txtEmail.val() },
                beforeSend: function () {
                    $("#btn_subscribe").button('loading');
                }
            });

            ajaxRequest.fail(function (data) {
                // error
                var $message = '<i class="icon-remove"></i> ' + data.responseText;
                $("#subscribe_modal").modal();
                $("#subscribe_form_message").removeClass("alert alert-success");
                $("#subscribe_form_message").addClass("alert alert-error").html($message);
                $("#subscribe_form_message").css({ opacity: 0 }).animate({ opacity: 1 }, 200).fadeIn(1000);
                $("#btn_subscribe").button('reset');
            });

            ajaxRequest.done(function (response) {
                // done
                var $message = '<i class="icon-ok"></i> ' + response;
                $("#subscribe_modal").modal();
                $("#subscribe_form_message").removeClass("alert alert-error");
                $("#subscribe_form_message").addClass("alert alert-success").html($message);
                $("#subscribe_form_message").css({ opacity: 0 }).animate({ opacity: 1 }, 200).fadeIn(1000);
            });

            ajaxRequest.always(function () {
                // complete
                $("#btn_subscribe").button('reset');
            });
        }
    });
});

function init_SubscribeFormValidator() {
    $('#frm_subscribe').validate({
        messages: {
            txtSubscribeEmail: {
                required: '<i class="icon-remove-sign"></i> required.',
                email: '<i class="icon-info-sign"></i> invalid.</b>'
            }
        },
        errorPlacement: function (error, element) {
            error.css({ 'font-size': '12px' }).insertAfter(element);
            error.css({ left: element.position().left + (element.width() - error.width()), top: element.position().top + 6, position: 'absolute', 'z-index': 1100 });
            $(window).resize(function () {
                error.remove();
            });
        },
        invalidHandler: function (event, validator) {
            // 'this' refers to the form
            var errors = validator.numberOfInvalids();
            if (errors) {
            } else {
            }
        }
    });
}