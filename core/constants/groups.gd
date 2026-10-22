class_name Groups
## Nomes de grupos de nós usados entre sistemas. Use estas constantes em vez de
## texto solto (`get_first_node_in_group(Groups.PLAYER)`): erro de digitação vira
## erro de compilação.

## O player atual (um só).
const PLAYER := &"player"
## Todos os inimigos vivos.
const ENEMY := &"enemy"
## Nós que salvam/carregam o próprio estado via SaveSystem
## (implementam `save_state(data)` e `load_state(data)`).
const PERSIST := &"persist"
