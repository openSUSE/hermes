// Place your application-specific JavaScript functions and classes here
// This file is automatically included by javascript_include_tag :defaults


// removes filter and updates filter ids
// last filter gets hidden to ensure there's always a filter to
// clone for add_filter()
function remove_filter(element) {
  element.parentNode.parentNode.remove();
  recalc_filter_ids();
}

// updates all filter ids to be in the range [0..filter_count()[
function recalc_filter_ids() {
  fc = $('filter_count').value = filter_count();
  for(var i=0; i<fc; i++) {
    filter = $('filter_table').childElements()[0];
    filter.adjacent('select.param_select')[i].name = 'param_id_'+i;
    filter.adjacent('select.param_select')[i].id = 'param_id_'+i;
    filter.adjacent('select.filter_select')[i].name = 'filter_operator_'+i;
    filter.adjacent('select.filter_select')[i].id = 'filter_operator_'+i;
    filter.adjacent('input.filter_value_input')[i].name = 'filter_value_'+i;
    filter.adjacent('input.filter_value_input')[i].id = 'filter_value_'+i;

  }
}

function filter_count() {
  return $('filter_table').childElements()[0].adjacent('select.param_select').length;
  
}

