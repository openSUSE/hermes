// Place your application-specific JavaScript functions and classes here
// This file is automatically included by javascript_include_tag :defaults

//to save and restore filter values
var old_operator_hash = new Hash();
var old_value_hash = new Hash();
var special_operator_values = new Array('_mypackages', '_mypackagesstrict', '_myprojects','_myrequests', '_packagebugowner');

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

      filter.adjacent('.filter_value_input')[i].name = 'filter_value_'+i;
      filter.adjacent('.filter_value_input')[i].id = 'filter_value_'+i;

      param_select = filter.adjacent('select.param_select')[i];
      operator_select = filter.adjacent('select.filter_select')[i];
      
      //delete the old Observer and create a new one
      stop_observer(operator_select);

      add_observer(operator_select);

      special_operator_checks(param_select);
    }
  }

  function filter_count() {
    return $('filter_table').childElements()[0].adjacent('select.filter_select').length;
    
  }

  function stop_observer(element) {
    Event.stopObserving(element,'change',function(event) {
      special_operator_checks(Event.element(event))
    });
  }

  function add_observer(element) {
    Event.observe(element,'change',function(event) {
      special_operator_checks(Event.element(event)) 
    });
  }

  //change the filter input to select box on special operator selection
  function special_operator_checks(element) {

    id = $(element).name.match(/.$/);

    param_elem = $('param_id_' + id);
    operator_elem = $('filter_operator_' + id);
    filter_elem = $("filter_value_" + id);

    old_oper_value = old_operator_hash.get(operator_elem.id);
    selected_param_value = param_elem.options[param_elem.selectedIndex].text
    
    if ($('filter_value_' + id))
      current_filter_value = $('filter_value_' + id).value;
    else
      current_filter_value = '';

    if(operator_elem.value == 'special') {
      param_elem.disabled = true;

      if (old_oper_value != 'special' && old_oper_value != '' && old_oper_value != undefined)
        old_value_hash.set(operator_elem.id, $('filter_value_' + id).value);

      filter_elem.replace(select_tag(id,current_filter_value));

    } else if(old_oper_value == 'special' && operator_elem.value != 'special'){

        param_elem.disabled = false;

        if (old_value_hash.get(operator_elem.id))
          filter_elem.replace(input_tag(id,old_value_hash.get(operator_elem.id)));
        else
          filter_elem.replace(input_tag(id,""));
       
    } 

   old_operator_hash.set(operator_elem.id,operator_elem.value);

  }

  function in_array(a,p){
   for (i=0;i<a.length;i++)
    if (a[i] == p) return true
   return false
  }

  function select_tag(id,selected){
    sel_string = '<select id=filter_value_' + id + ' name=filter_value_' + id +' class=filter_value_input';
    special_operator_values.each(function(s){
      if (selected == s)
        sel_string += ' <option selected=selected>' + s + '</option>';
      else
        sel_string += ' <option>' + s + '</option>';
    })
    sel_string += "</select>";
    return sel_string;
  }

  function input_tag(id,value){
    input_string = '<input type=text id=filter_value_' + id + ' name=filter_value_' + id;
    input_string += ' class=filter_value_input ';
    if (value != '')
      input_string += 'value=' + value;
    input_string += ' </input>';
    return input_string;
  }

