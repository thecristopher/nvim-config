# Tree

`lua/core/tree/`: the explorer dressed by the franchise. Guides and folders come from `skin.tree`
(no expanders, the open or closed folder says it). A folder that is a room of `:Map` with errors or
TODOs left carries `skin.tree.left`, cleared rooms stay bare, and folders carry no git status or
diagnostics. Files carry their open review threads with a count (`core.threads.open_threads`, `User
EldentreeThreads`) and their ground messages (`User EldentreeMessages`), and the file just saved
glows (`EldenTreeFresh`). bufferline's offset is the explorer's one title (`chrome.tree` in the
ornaments, `EldenTreeTitle`), and the root row names the project.
