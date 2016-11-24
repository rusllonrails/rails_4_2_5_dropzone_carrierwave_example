window.DeviseImagesUpload =
  init: (url, invalid_type_message, missing_count_message) ->
    self = DeviseImagesUpload
    self.current_modal = $('#devise_image_validation_modal')
    self.validate_base_modal_init()
    self.invalid_type_message = invalid_type_message
    self.missing_count_message = missing_count_message
    self.reset_vars()

    myDropzone = new Dropzone(document.body,
      acceptedFiles: '.gif, .jpeg, .png, .jpg'
      url: url
      headers: { 'X-CSRF-Token': $('meta[name="csrf-token"]').attr 'content' }
      autoProcessQueue: false
      autoQueue: false
      previewsContainer: false
      parallelUploads: false
      uploadMultiple: false
      paramName: 'devise_images_params[file]'
      clickable: '#fileupload')

    self.init_callbacks(myDropzone)

  init_callbacks: (myDropzone)->
    myDropzone.on 'thumbnail', (file) ->
      if file.status != 'canceled'
        self = DeviseImagesUpload
        CubeDebug.log ' '
        CubeDebug.log 'LOAD FILE'
        width = (file.width || 0)
        height = (file.height || 0)
        validate_dimentions = width > 500 && height > 500 && self.check_ratio(width, height)
        validate_size = self.check_file_size(file.size)

        CubeDebug.log file.status
        CubeDebug.log 'width: ' + width + ', ' + 'height: ' + height
        CubeDebug.log 'validate_dimentions: ' + validate_dimentions
        CubeDebug.log 'validate_size: ' + validate_size

        if validate_dimentions && validate_size
          myDropzone.processFile(file)
        else
          myDropzone.removeFile(file)
      else
        CubeDebug.log 'canceled'
        @_thumbnailQueue = []
        DeviseImagesUpload.forced_reset(@)
      return

    myDropzone.on 'sending', (file, xhr, formData) ->
      CubeDebug.log 'send'
      cube_id = SetCubeId.cube_id
      formData.append 'cube_id', cube_id if cube_id
      return

    myDropzone.on 'beforeadd', (files)->
      CubeDebug.log 'beforeadd'
      self = DeviseImagesUpload
      self.enable_upload()

      if !self.check_missing_count(files)
        self.forced_reset(@)
        self.show_bad_missing_count_popup()
        self.disable_upload()
      return

    myDropzone.on 'queuecomplete', (file)->
      CubeDebug.log ' '
      CubeDebug.log 'queuecomplete'
      self = DeviseImagesUpload

      if self.xhr_status >= 400 || self.xhr_status == 0

        names = self.bad_file_names.uniq_array()
        CubeDebug.log 'queuecomplete | bad_file_names'
        CubeDebug.log names

        if self.bad_files_length
          DeviImageCombineModal.show(names)
        else
          BadRequestPopup.show()
      else
        self.errors_block(@)

      self.forced_reset(@)
      self.reset_vars()
      self.disable_upload()

      setTimeout (->
        self.set_percent(0)
      ), 1200
      return

    myDropzone.on 'error', (file, textStatus, xhr) ->
      self = DeviseImagesUpload
      accepted_files = @getAcceptedFiles().length

      CubeDebug.log 'error | xhr.status: ' + (xhr.status) if xhr
      CubeDebug.log 'error | accepted_files: ' + accepted_files

      if xhr && (xhr.status >= 400 || xhr.status == 0)
        CubeDebug.log "error | BAD REQUEST"
        self.xhr_status = xhr.status
        window.cancel_devise_images_upload = true

        files = myDropzone.getAddedFiles()

        CubeDebug.log 'error | getAddedFiles length: ' + files.length

        for file in files
          file.status = Dropzone.CANCELED
      return

    myDropzone.on 'success', (file, response) ->
      CubeDebug.log ' '
      CubeDebug.log 'success'
      CubeDebug.log file

      DeviseImagesUpload.render_collection(response)
      DeviseImagesUpload.calculate_percent(@getAcceptedFiles().length)
      CubeDebug.log 'success | accepted_files: ' + @getAcceptedFiles().length
      CubeDebug.log 'success | response_length: ' + (DeviseImagesUpload.response_length)
      return

    myDropzone.on 'removedfile', (file) ->
      self = DeviseImagesUpload
      self.update_bad_files_length(file)
      accepted_files = @getAcceptedFiles().length

      CubeDebug.log 'removedfile | delete name: ' + file.name
      CubeDebug.log 'removedfile | bad_files_length: ' + self.bad_files_length
      CubeDebug.log 'removedfile | accepted_files: ' + accepted_files
      CubeDebug.log 'removedfile | xhr_status: ' + self.xhr_status

      if accepted_files == 0 && self.xhr_status == undefined
        self.errors_block(@)
        self.disable_upload()
      return

  enable_upload: ->
    window.current_device_upload_or_destroy = true
    $('#fileupload').addClass 'disabled'
    ImageSelection.add_disable_for_some_buttons()
    CubeBreadcrumbs.add_or_remove_disable_for_insta_devise_tabs('add')

  disable_upload: ->
    window.current_device_upload_or_destroy = false
    $('#fileupload').removeClass 'disabled'
    ImageSelection.remove_disable_for_some_buttons()
    CubeBreadcrumbs.add_or_remove_disable_for_insta_devise_tabs('remove')

  set_percent: (percent)->
    $('#progress-bar').css 'width', (percent || 0) + '%'
    $('#progress-bar').attr 'aria-valuenow', (percent || 0)

  forced_reset: (myDropzone)->
    myDropzone.disable()
    myDropzone.files = []
    myDropzone.enable()

  errors_block: (myDropzone)->
    self = DeviseImagesUpload

    if self.bad_files_length > 0
      self.show_bad_files_popop()

    self.reset_vars()

    myDropzone.disable()
    myDropzone.enable()

  reset_vars: ->
    DeviseImagesUpload.bad_files_length = 0
    DeviseImagesUpload.response_length = 0
    DeviseImagesUpload.bad_file_names = []
    window.cancel_devise_images_upload = false
    DeviseImagesUpload.xhr_status = undefined
    window.current_device_upload_or_destroy = undefined

  update_bad_files_length: (file)->
    bad_files_length = DeviseImagesUpload.bad_files_length + 1
    DeviseImagesUpload.bad_files_length = bad_files_length
    DeviseImagesUpload.bad_file_names.push(file.name)

  check_ratio: (width, height)->
    ratio = if width > height
      width/height
    else
      height/width

    if ratio > 3.0
      return false
    else
      return true

  check_file_size: (size)->
    if size and size < 10000000
      return true
    else
      return false

  get_missing_count: ->
    images_count = $('#devise_images_list').children().length
    valid_count = 500
    missing_count = valid_count - (images_count || 0)

  check_missing_count: (files)->
    missing_count = DeviseImagesUpload.get_missing_count()
    accepted_files = files.length
    CubeDebug.log 'check_missing_count'
    CubeDebug.log 'accepted_files: ' + accepted_files

    if missing_count > 0 && accepted_files <= missing_count
      return true
    else
      window.cancel_devise_images_upload = true
      return false

  show_bad_missing_count_popup: ->
    self = DeviseImagesUpload
    missing_count = self.get_missing_count()

    images_counter = plural_str(missing_count, "фотография", "фотографии", "фотографий")
    message = self.missing_count_message + missing_count + ' ' + images_counter
    DeviseImagesUpload.current_modal.find('#condition_message').addClass 'hidden'
    DeviseImagesUpload.current_modal.find('ul').addClass 'hidden'
    self.activate_validate_base_modal(message)

  show_bad_files_popop: ->
    self = DeviseImagesUpload
    names = self.bad_file_names.uniq_array()

    if names.length > 0
      message = self.invalid_type_message + self.wrap_bad_file_names(names).join(', ')
      self.activate_validate_base_modal(message)

  calculate_percent: (accepted_files_length)->
    percent = parseInt(DeviseImagesUpload.response_length * 100 / accepted_files_length)
    CubeDebug.log 'percent: ' + percent
    DeviseImagesUpload.set_percent(percent)

  render_collection: (response) ->
    if response && response.image
      response_length = DeviseImagesUpload.response_length
      DeviseImagesUpload.response_length = response_length + 1
      DeviseImagesUpload.render_item(response.image)

  render_item: (item) ->
    new_item_html = window.devise_image_item_template(item)
    $('#devise_images_list').append(new_item_html)

  activate_validate_base_modal: (message) ->
    CubeDebug.log 'message: ' + message
    DeviseImagesUpload.current_modal.modal('show')
    DeviseImagesUpload.current_modal.find('#error_message').append(message)

  validate_base_modal_init: ->
    current_modal = DeviseImagesUpload.current_modal
    current_modal.modal

    current_modal.on 'show.bs.modal', (e) ->
      current_modal.find('#error_message').empty()
      return

    current_modal.on 'hidden.bs.modal', (e) ->
      current_modal.find('#error_message').empty()
      DeviseImagesUpload.current_modal.find('#condition_message').removeClass 'hidden'
      DeviseImagesUpload.current_modal.find('ul').removeClass 'hidden'
      return

  wrap_bad_file_names: (names) ->
    wrapped_names = []
    $.each names, (index, name) ->
      html = '<span class="b-loading-error__filename">' + name + '</span>'
      wrapped_names.push(html)

    wrapped_names = if wrapped_names.length > 0
      wrapped_names
    else
      ''
