Jekyll::Hooks.register [:posts, :pages], :post_render do |doc|
  doc.output = doc.output.gsub(
    '<div class="footnotes"',
    '<hr /><div class="footnotes"'
  )
end
