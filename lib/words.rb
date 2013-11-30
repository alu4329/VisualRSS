  def truncate(text, length = 20, end_string = '…')
    words = text.split()
    words[0..(length-1)].join(' ') + (words.length > length ? end_string : '')
  end