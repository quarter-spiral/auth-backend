$(function() {
  $('body').on('click', '[data-confirm]', function(e) {
    if (!confirm($(this).data('confirm'))) {
      e.preventDefault();
    }
  });

  $('body').on('click', '[data-method]', function(e) {
    e.preventDefault();
    var self = $(this);
    var form = $('<form method="POST"></form>')
    form.attr('action', self.attr('href'))
    var method_field = $('<input type="hidden" name="_method"/>')
    method_field.val(self.data('method'))
    form.append(method_field)
    form.submit();
  });
});
