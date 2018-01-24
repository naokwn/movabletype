<content-fields>
  <form name="content-type-form" action={ CMSScriptURI } method="POST">
    <input type="hidden" name="__mode" value="save">
    <input type="hidden" name="blog_id" value={ opts.blog_id }>
    <input type="hidden" name="magic_token" value={ opts.magic_token }>
    <input type="hidden" name="return_args" value={ opts.return_args }>
    <input type="hidden" name="_type" value="content_type">
    <input type="hidden" name="id" value={ opts.id }>
    <input if={ data } type="hidden" name="data" value={ data }>

    <div class="row">
      <div class="col">
        <div if={ opts.id }  id="name-field" class="form-group">
          <h3>{opts.name} <button type="button" class="btn btn-link" data-toggle="modal" data-target="#editDetail">{ trans('Edit') }</button></h3>
          <div id="editDetail" class="modal" role="dialog" aria-labelledby="editDetail" aria-hidden="true">
            <div class="modal-dialog modal-lg" role="document">
              <div class="modal-content">
                <div class="modal-header">
                  <h4 class="modal-title">{ trans('Content Type') }</h4>
                  <button type="button" class="close" data-dismiss="modal" aria-label="Close">
                    <span aria-hidden="true">&times;</span>
                  </button>
                </div>
                <div class="modal-body">
                  <div class="col">
                    <div id="name-field" class="form-group">
                      <label for="name" class="form-control-label">{ trans('Content Type Name') } <span class="badge badge-danger">{ trans('Required') }</span></label>
                      <input type="text" name="name" id="name" class="form-control html5-form" value={opts.name} onkeypress={ stopSubmitting } required>
                    </div>
                  </div>
                  <div class="col">
                    <div id="description-field" class="form-group">
                      <label for="description" class="form-control-label">{ trans('Description') }</label>
                      <textarea name="description" id="description" class="form-control">{ opts.description }</textarea>
                    </div>
                  </div>
                  <div class="col">
                    <div id="unique_id-field" class="form-group">
                      <label for="unique_id" class="form-control-label">{ trans('Unique ID') }</label>
                        <input type="text" class="form-control-plaintext w-50" id="unieuq_id" value={ opts.unique_id } readonly>
                    </div>
                  </div>
                  <div class="col">
                    <div id="user_disp_option-field" class="form-group">
                      <label for="user_disp_option">{ trans('Allow users to change the display and sort of fields by display option') }</label>
                      <input type="checkbox" class="mt-switch form-control" id="user_disp_option" checked={ opts.user_disp_option } name="user_disp_option"><label for="user_disp_option" class="last-child">{ trans('Allow users to change the display and sort of fields by display option') }</label>
                    </div>
                  </div>
                </div>
              <div class="modal-footer">
                <button type="button" class="btn btn-default" data-dismiss="modal">{ trans('close') }</button>
              </div>
              </div>
            </div>
          </div>
        </div>
        <div if={ !opts.id }  id="name-field" class="form-group">
          <label for="name" class="form-control-label">{ trans('Content Type Name') } <span class="badge badge-danger">{ trans('Required') }</span></label>
          <input type="text" name="name" id="name" class="form-control html5-form" value={opts.name} onkeypress={ stopSubmitting } required>
        </div>
      </div>
    </div>
  </form>

  <form>
    <fieldset id="content-fields" class="form-group">
      <legend class="h3">{ trans('Content Fields') }</legend>
      <div id="installed-fields" class="sortable" ondrop={ onDrop } ondragover={ onDragOver }>
        <div show={ isEmpty }>{ trans('Please add a piece of content field.') }</div>
        <div class="mt-draggable"  draggable="true" aria-grabbed="false" each={ fields } data-is="content-field" ondragstart={ onDragStart } ondragend={ onDragEnd }></div>
      </div>
    </fieldset>
  </form>
  <button type="button" class="btn btn-primary" disabled={ !canSubmit() } onclick={ submit }>{ trans("Save") }</button>

  <style>
    .placeholder{
        height:26px;
        margin:4px;
        margin-left:10px;
        border-width:2px;
        border-style:dashed;
        border-radius:4px;
        border-color:#aaa;
    }
  </style>

  <script>
    self = this
    self.fields = opts.fields
    self.isEmpty = self.fields.length > 0 ? false : true
    self.data = ""
    self.droppable = false
    self.observer = opts.observer
    self.dragged = null
    self.draggedItem = null
    self.placeholder = document.createElement("div")
    self.placeholder.className = 'placeholder'

    self.observer.on('mtDragStart', function() {
      self.droppable = true
    })

    self.observer.on('mtDragEnd', function() {
      self.droppable = false
      self.onDragEnd()
    })

    jQuery(document).on('hide.bs.modal', '#editDetail', function(e){
      if ( jQuery('#name-field > input').mtValidate('simple') ) {
        self.opts.name = jQuery('#name-field > input').val()
        setDirty(true)
        self.update()
      }
      else {
        return false
      }
    })

    stopSubmitting(e) {
      if (e.which == 13) {
        e.preventDefault()
        return false
      }
      return true
    }

    onDragOver(e) {
      // Allowed only for Content Field and Content Field Type.
      if (self.droppable ) {
        if (e.target.className != 'sortable' && e.target.className != 'mt-draggable') {
          e.preventDefault()
          return
        }

        if (self.dragged) {
          if (e.target.className == 'mt-draggable') {
            // Inside the dragOver method
            self.over = e.target
            var targetRect = e.target.getBoundingClientRect()
            var parent = e.target.parentNode
            if ((e.clientY - targetRect.top) / targetRect.height > 0.5) {
              parent.insertBefore(self.placeholder, e.target.nextElementSibling)
            }
            else {
              parent.insertBefore(this.placeholder, e.target)
            }
          }
          if (e.target.className == 'sortable') {
            var fields = e.target.getElementsByClassName('mt-draggable')
            if (fields.length == 0 || ( fields.length == 1 && fields[0] == self.dragged)){
              e.target.appendChild(self.placeholder);
            }
          }

        }
        else {
          // Dragged from content field types
          e.target.parentNode.appendChild(self.placeholder)
        }

        e.preventDefault()
      }
    }

    onDrop(e) {
      if (self.dragged) {
        var pos = 0
        var children
        if (self.placeholder.parentNode) {
          children = self.placeholder.parentNode.children
        }
        for(var i = 0; i < children.length; i++){
          if(children[i] == self.placeholder) 
          break;
          if(children[i] != self.dragged && children[i].classList.contains("mt-draggable")) {
            pos++;
          }
        }
        self._moveField(self.draggedItem, pos)
        setDirty(true)
        self.update()
      }
      else {
        // Drag from field list
        var fieldType = e.dataTransfer.getData('text')
        var field = jQuery("[data-field-type='" + fieldType + "']")
        var fieldTypeLabel = field.data('field-label')

        newId = Math.random().toString(36).slice(-8)
        field = {
          'type': fieldType,
          'typeLabel' : fieldTypeLabel,
          'id' : newId,
          'isNew': true,
          'isShow': 'show'
        }
        self.fields.push(field)
        setDirty(true)
        self.update({
          isEmpty: false
        })
      }

      e.preventDefault()
    }

    onDragStart(e) {
      self.dragged = e.target
      self.draggedItem = e.item
      e.dataTransfer.setData('text', e.item.id)
      self.droppable = true
    }

    onDragEnd(e) {
      if (self.placeholder.parentNode) {
        self.placeholder.parentNode.removeChild(self.placeholder)
      }
      self.droppable = false
      self.dragged = null
      self.draggedItem = null
      self.update()
    }

    _moveField(item, pos){
      for (var i = 0; i < self.fields.length; i++) {
        var field = self.fields[i];
        if (field.id == item.id) {
          self.fields.splice(i, 1)
          break
        }
      }
      self.fields.splice(pos, 0, field)
      for (var i = 0; i < self.fields.length; i++) {
        self.fields[i].order = i + 1
      }
    }

   _validateFields() {
     var requiredFieldsAreValid    = jQuery('.html5-form')
                                        .mtValidate('simple')
     var textFieldsInTableAreValid = jQuery('.values-option-table input[type=text]')
                                        .mtValidate('simple');
     var tableIsValid              = jQuery('.values-option-table')
                                        .mtValidate('selection-field-values-option')
     var contentFieldBlockIsValid  = jQuery('.content-field-block')
                                        .mtValidate('content-field-block')

     return requiredFieldsAreValid && textFieldsInTableAreValid
         && tableIsValid && contentFieldBlockIsValid
    }

    canSubmit() {
      if (self.fields.length == 0) {
        return true
      }
      var invalidFields = self.fields.filter(function (field) {
        return opts.invalid_types[field.type]
      })
      return invalidFields.length == 0 ? true : false
    }

    submit(e) {
      if (!self.canSubmit()) {
        return
      }

      if ( !self._validateFields() ) {
        return
      }

      setDirty(false)
      fieldOptions = [];
      if (self.fields) {
        var child = self.tags['content-field']
        if (child) {
          if (!Array.isArray(child)) {
            child = [ child ]
          }

          child.forEach(function (c, i) {
            var field = c.tags[c.type]
            var options = field.gatheringData()
            var data = {}
            data.type = c.type
            data.options = options
            if ( c.isNew ) {
              data.order = i + 1
            }
            else {
              data.id = c.id
              var innerField = self.fields.filter( function (v) {
                return v.id == c.id
              })
              if (innerField.length) {
                data.order = innerField[0].order
              }
              else {
                data.order = i + 1
              }
            }
            fieldOptions.push(data)
          })
          self.data = JSON.stringify(fieldOptions)
        }
      }
      else {
        self.data = ""
      }
      self.update()
      document.forms['content-type-form'].submit()
    }

  </script>
</content-fields>
