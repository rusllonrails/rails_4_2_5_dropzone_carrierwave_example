window.PicturesUpload =
  init: (url) ->
    self = PicturesUpload

    myDropzone = new Dropzone(document.body,
      acceptedFiles: '.gif, .jpeg, .png, .jpg'
      url: url
      headers: { 'X-CSRF-Token': $('meta[name="csrf-token"]').attr 'content' }
      autoProcessQueue: false
      autoQueue: false
      previewsContainer: false
      parallelUploads: false
      uploadMultiple: false
      paramName: 'file'
      clickable: '#fileupload')

    self.init_callbacks(myDropzone)

    $(document).on 'click', '.js-remove-image', ->
      $(this).closest('div').remove()

  init_callbacks: (myDropzone)->
    myDropzone.on 'thumbnail', (file) ->
      console.log 'thumbnail'
      myDropzone.processFile(file)
      return

    myDropzone.on 'sending', (file, xhr, formData) ->
      console.log 'send'
      return

    myDropzone.on 'beforeadd', (files)->
      console.log 'beforeadd'
      return

    myDropzone.on 'queuecomplete', (file)->
      console.log 'queuecomplete'
      return

    myDropzone.on 'error', (file, textStatus, xhr) ->
      console.log 'error'
      return

    myDropzone.on 'success', (file, response) ->
      console.log 'success'

      id = response.id
      name = response.name
      size = response.size
      delete_url = response.delete_url

      new_image_html = "<div id='image_" + id + "'>" + name + "(" + size + ")" + "<a class='js-remove-image' href='" + delete_url + "' data-method='delete' data-remote='true'>X</a></div>"

      $('#devise_images_list').append(new_image_html)

      return

    myDropzone.on 'removedfile', (file) ->
      console.log 'removedfile'
      return
