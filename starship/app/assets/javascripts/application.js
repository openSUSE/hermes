// Place your application-specific JavaScript functions and classes here
// This file is automatically included by javascript_include_tag :defaults


  function remove_filter(element) {
    $(element).parent().parent().remove();
    recalc_filter_ids();
    return false;
  }

  // updates all filter ids to be in the range [0..filter_count()[
  function recalc_filter_ids() {
    filters = $('#filter_table > .filter_line')
    $('#filter_count').val(filters.size());
    filters.each(function(index) {
        $(this).find('.param_select')[0].name = 'param_id_' + index;
        $(this).find('.param_select')[0].id = 'param_id_' + index;
        $(this).find('.filter_select')[0].name = 'filter_operator_' + index;
        $(this).find('.filter_select')[0].id = 'filter_operator_' + index;
        $(this).find('.filter_value_input')[0].name = 'filter_value_' + index;
        $(this).find('.filter_value_input')[0].id = 'filter_value_' + index;
    });
  }
