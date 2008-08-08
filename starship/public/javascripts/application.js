// Place your application-specific JavaScript functions and classes here
// This file is automatically included by javascript_include_tag :defaults

//to save and restore filter values
var old_operator_hash = new Hash();
var old_value_hash = new Hash();

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

    param_select = filter.adjacent('select.param_select')[i];
    
    //delete the old Observer and create a new one
    stop_observer(param_select);
    add_observer(param_select);

    special_operator_checks(param_select);
  }
}

function filter_count() {
  return $('filter_table').childElements()[0].adjacent('select.param_select').length;
  
}

//observer for the special operator (if parameter == package || parameter == project)
function set_special_operator_observer() {

  current_id = filter_count() - 1;
  operator_element = "filter_operator_" + current_id;

  old_operator_hash.set(operator_element,$(operator_element).value);
  
  add_observer(operator_element);

}

function stop_observer(element) {
  Event.stopObserving(element,'change',function(event) {
    pecial_operator_checks(Event.element(event))
  });
}

function add_observer(element) {
  Event.observe(element,'change',function(event) {
      special_operator_checks(Event.element(event)) 
  });
}

//check if the parameter is package or project to fix the filter value input
function special_operator_checks(element) {

//  alert(element.id);
  id = $(element).name.match(/.$/);

  param_elem = $('param_id_' + id);
  operator_elem = $('filter_operator_' + id);
  filter_elem = $("filter_value_" + id);

  old_oper_value = old_operator_hash.get(operator_elem.id);

  
  if( (old_oper_value != 'special' || old_oper_value == 'special'  ) &&  operator_elem.value == 'special') {
//  if( old_oper_value != 'special' &&  operator_elem.value == 'special') {
    if(param_elem.options[param_elem.selectedIndex].text == 'package') {
      if (old_oper_value != 'special')
        old_value_hash.set(operator_elem.id, $('filter_value_' + id).value);
      filter_elem.value =  '_mypackages';
      filter_elem.readOnly = true;
    } else if(param_elem.options[param_elem.selectedIndex].text == 'project') {
      if (old_oper_value != 'special')
        old_value_hash.set(operator_elem.id, $('filter_value_' + id).value);
      filter_elem.value =  '_myprojects';
      filter_elem.readOnly = true;
    } else {
      filter_elem.value =  old_value_hash.get(operator_elem.id);
      filter_elem.readOnly = false;
    }

  } else if(old_oper_value == 'special' && operator_elem.value != 'special' ){ 
      if (old_value_hash.get(operator_elem.id) != '') {
        filter_elem.value =  old_value_hash.get(operator_elem.id);
        filter_elem.readOnly = false;
      } else {
        filter_elem.value = '';
        filter_elem.readOnly = false;
	  }
  } 
  old_operator_hash.set(operator_elem.id,operator_elem.value);
}

