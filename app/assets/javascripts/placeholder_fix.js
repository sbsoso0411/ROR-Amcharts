(function ($) {
    'use strict';
    $(function () {
        return;
        $('[placeholder]')
            .focus(function () {
                var input = $(this);
                if (input.attr('type') != 'password' && input.val() === input.attr('placeholder')) {
                    input.val('').removeClass('placeholder');
                }
            })
            .blur(function () {
                var input = $(this);
                if (input.attr('type') != 'password' && input.val() === '' || input.val() === input.attr('placeholder')) {
                    input.addClass('placeholder').val(input.attr('placeholder'));
                }
            })
            .blur()
            .parents('form').submit(function () {
                $(this).find('[placeholder]').each(function () {
                    var input = $(this);
                    if (input.attr('type') != 'password' && input.val() === input.attr('placeholder')) {
                        input.val('');
                    }
                });
            });
    });
})(jQuery);