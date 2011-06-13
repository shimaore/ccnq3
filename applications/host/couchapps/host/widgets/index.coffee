
header ->
  h1 @title or 'Untitled'
  nav ->
    ul ->
      li -> a href: '#/form', -> 'Home'
  section ->
    div id: 'content', -> 'No content yet'
  section ->
    div id: 'log'
  footer ->
    p '&copy; 2011 Stéphane Alnet'
