;24L-3001 Romesha Afzaal 
;24L-3024 Aliza Nadeem 


[org 0x0100]
jmp start

; Game state
game_over_flag:        db 0
bonus_flag:            db 0
player_score:          dw 0
scroll_active:         db 0
time_counter:          dw 0
game_speed:            dw 7
game_paused:           db 0
; Enemy car positions
leftLane equ 48
midLane equ 70
rightLane equ 96

LeftEnemy1Status db 0
LeftEnemy1Pos dw 0
LeftEnemy2Status db 0
LeftEnemy2Pos dw 0

MidEnemy1Status db 0
MidEnemy1Pos dw 0
MidEnemy2Status db 0
MidEnemy2Pos dw 0

RightEnemy1Status db 0
RightEnemy1Pos dw 0
RightEnemy2Status db 0
RightEnemy2Pos dw 0

CurrentLane db 0
EnemyTimer dw 0
ENEMY_SPACE_VERTICAL equ 4
ENEMY_SPACE_HORIZONTAL equ 3
ENEMY_DELAY equ 8
RandomValue dw 0x1234

; Bonus system
BonusStatus db 0
BonusLanePos db 0
BonusPosition dw 0
BonusTimer dw 0
bonusDelayt equ 20
BONUS_POINTS equ 50

; Player information
player_location:       dw 2792
current_player_lane:   db 1
previous_keyboard_isr: dd 0
previous_timer_isr:    dd 0

; Messages
exit_text1:     db 'Exit Game?', 0
exit_text2:     db 'Are you sure?', 0
exit_text3:     db 'Y/N', 0
exit_text3_formatted:  db '[ Y ]   [ N ]', 0
final_text1:    db 'Thanks for playing!', 0
final_text2:    db 'Final Score: ', 0
screen_storage: times 100 dw 0

; Loading screen text
creator_names: db 'ROMESHA AFZAAL 24L-3001 AND ALIZA NADEEM 24L-3024', 0
section_text: db 'FROM BSSE-3B PRESENT', 0
game_title: db 'RACECAR GAME', 0
loading_text: db 'LOADING...', 0
key_prompt: db 'PRESS ANY KEY TO CONTINUE', 0

;For smoothness 
wait_vsync:
push ax
push dx
push cx

mov dx, 0x3DA
mov cx, 5000

.wait_end:
in al, dx
test al, 0x08
jz .wait_start
dec cx
jnz .wait_end
jmp .complete

.wait_start:
mov cx, 5000
.wait_loop:
in al, dx
test al, 0x08
jnz .complete
dec cx
jnz .wait_loop

.complete:
pop cx
pop dx
pop ax
ret

;LOADING SCREEN 
display_string:
push bp
mov bp, sp
push es
push ax
push cx
push si
push di
mov ax, 0xb800
mov es, ax
mov ax, [bp+6]
mov bx, 80
mul bx
add ax, [bp+8]
shl ax, 1
mov di, ax

mov si, [bp+4]
mov ah, [bp+10]
.char_loop:
lodsb
cmp al, 0
je .string_done
stosw
jmp .char_loop
.string_done:
pop di
pop si
pop cx
pop ax
pop es
pop bp
ret 8

clear_display:
push es
push ax
push di
mov ax, 0xb800
mov es, ax
mov di, 0
.clear_loop:
mov word[es:di], 0x0120
add di, 2
cmp di, 4000
jne .clear_loop
pop di
pop ax
pop es
ret

draw_frame:
push bp
mov bp, sp
push es
push ax
push di
mov ax, 0xb800
mov es, ax
mov ax, 15
mov bx, 80
mul bx
add ax, 25
shl ax, 1
mov di, ax
mov ax, 0x0F5B
mov [es:di], ax
add di, 62
mov ax, 0x0F5D
mov [es:di], ax
pop di
pop ax
pop es
pop bp
ret

update_progress_bar:
push bp
mov bp, sp
push es
push ax
push bx
push cx
push di
mov ax, 0xb800
mov es, ax
mov ax, [bp+4]
mov bx, 30
mul bx
mov bx, 100
div bx
mov cx, ax
mov di, 15 * 160 + 26 * 2
mov ax, 0x0BDB
.bar_loop:
jcxz .bar_done
mov [es:di], ax
add di, 2
dec cx
jmp .bar_loop
.bar_done:
pop di
pop cx
pop bx
pop ax
pop es
pop bp
ret 2

show_percentage:
push bp
mov bp, sp
pusha
push es
mov ax, 0xb800
mov es, ax
mov di, 17 * 160 + 38 * 2
mov ax, [bp+4]
mov bx, ax
xor dx, dx
cmp ax, 100
jne .not_full
mov ax, 0x0E31
stosw
mov ax, 0x0E30
stosw
mov ax, 0x0E30
stosw
mov ax, 0x0E25
stosw
jmp .percent_done
.not_full:
xor dx, dx
mov ax, bx
mov cl, 10
div cl
cmp al, 0
je .skip_tens
add al, '0'
mov ah, 0x0E
stosw
.skip_tens:
mov al, ah
add al, '0'
mov ah, 0x0E
stosw
mov ax, 0x0E25
stosw
mov cx, 6
.clean_loop:
mov ax, 0x0E20
stosw
loop .clean_loop
.percent_done:
pop es
popa
pop bp
ret 2

;TIMER INT 
timer_handler:
push ax
push ds
push cs
pop ds
cmp byte [game_paused], 1
je .timer_exit
inc word [time_counter]
mov ax, [time_counter]
xor dx, dx
div word [game_speed]
cmp dx, 0
jne .timer_exit
mov byte [scroll_active], 1
.timer_exit:
mov al, 0x20
out 0x20, al
pop ds
pop ax
iret

;KEYBOARD INT 
keyboard_handler:
push ax
push ds
push es
push cs
pop ds
cmp byte [game_paused], 1
je .check_exit
cmp byte [game_over_flag], 1
je .keyboard_exit
in al, 0x60
cmp al, 0x01
je .escape_pressed
cmp al, 0x4B
je .left_pressed
cmp al, 0x4D
je .right_pressed
jmp .keyboard_exit
.escape_pressed:
cmp byte [game_paused], 1
je .keyboard_exit
mov byte [game_paused], 1
call show_exit_dialog
jmp .keyboard_exit
.left_pressed:
call wait_vsync
call clear_player_car
call move_car_left
jmp .keyboard_exit
.right_pressed:
call wait_vsync
call clear_player_car
call move_car_right
jmp .keyboard_exit
.check_exit:
in al, 0x60
cmp al, 0x15
je .exit_confirmed
cmp al, 0x31
je .continue_game
jmp .keyboard_exit
.exit_confirmed:
call display_final_score
mov byte [game_over_flag], 1
jmp .keyboard_exit
.continue_game:
call hide_exit_dialog
mov byte [game_paused], 0
push word [cs:player_location]
push 0x4520
call drawCar
jmp .keyboard_exit
.keyboard_exit:
mov al, 0x20
out 0x20, al
pop es
pop ds
pop ax
iret

;ESC LOGIC 
show_exit_dialog:
pusha
push es
push ds
mov ax, 0xB800
mov ds, ax
push cs
pop es
mov si, 160*10 + 60
mov cx, 5
mov di, screen_storage
.save_screen:
push cx
mov cx, 20
rep movsw
add si, 160 - 40
pop cx
loop .save_screen
mov ax, 0xB800
mov es, ax
push cs
pop ds
mov di, 160*10 + 60
mov cx, 5
.draw_background:
push cx
push di
mov cx, 20
mov ax, 0x4F20
rep stosw
pop di
add di, 160
pop cx
loop .draw_background
mov di, 160*11 + 70
mov si, exit_text1
call show_dialog_text
mov di, 160*12 + 66
mov si, exit_text2
call show_dialog_text
mov di, 160*13 + 64
mov si, exit_text3_formatted
call show_dialog_text
pop ds
pop es
popa
ret

hide_exit_dialog:
pusha
push es
mov ax, 0xB800
mov es, ax
mov di, 160*10 + 60
mov si, screen_storage
mov cx, 5
.restore_screen:
push cx
mov cx, 20
rep movsw
add di, 160 - 40
pop cx
loop .restore_screen
pop es
popa
ret

show_dialog_text:
pusha
mov ah, 0x4F
.text_loop:
lodsb
cmp al, 0
je .text_done
stosw
jmp .text_loop
.text_done:
popa
ret

display_final_score:
pusha
push es
mov ax, 0xB800
mov es, ax
mov di, 0
mov ax, 0x0720
mov cx, 2000
rep stosw
mov di, 160*10 + 60
mov si, final_text1
mov ah, 0x0E
.text_loop1:
lodsb
cmp al, 0
je .show_score_text
stosw
jmp .text_loop1
.show_score_text:
mov di, 160*12 + 60
mov si, final_text2
mov ah, 0x0E
.text_loop2:
lodsb
cmp al, 0
je .display_score
stosw
jmp .text_loop2
.display_score:
mov di, 160*12 + 86
push cs
pop ds
mov ax, [player_score]
mov bx, 10
mov cx, 0
.score_loop:
xor dx, dx
div bx
add dl, '0'
push dx
inc cx
cmp ax, 0
jne .score_loop
.display_digits:
pop dx
mov al, dl
mov ah, 0x0E
stosw
loop .display_digits
mov ah, 0
int 0x16
pop es
popa
ret

;PLAYER CAR LOGIC 
move_car_left:
cmp byte [cs:current_player_lane], 0
je .no_movement
dec byte [cs:current_player_lane]
sub word [cs:player_location], 26
push word [cs:player_location]
push 0x4520
call drawCar
.no_movement:
ret

move_car_right:
cmp byte [cs:current_player_lane], 2
je .no_movement
inc byte [cs:current_player_lane]
add word [cs:player_location], 26
push word [cs:player_location]
push 0x4520
call drawCar
.no_movement:
ret

;INTERRUPT MANAGEMENT 
setup_keyboard:
push ax
push es
cli
mov ax, 0
mov es, ax
mov ax, [es:9*4]
mov word [cs:previous_keyboard_isr], ax
mov ax, [es:9*4+2]
mov word [cs:previous_keyboard_isr+2], ax
mov ax, keyboard_handler
mov [es:9*4], ax
mov [es:9*4+2], cs
sti
pop es
pop ax
ret

setup_timer:
push ax
push es
cli
mov ax, 0
mov es, ax
mov ax, [es:8*4]
mov word [cs:previous_timer_isr], ax
mov ax, [es:8*4+2]
mov word [cs:previous_timer_isr+2], ax
mov ax, timer_handler
mov [es:8*4], ax
mov [es:8*4+2], cs
sti
pop es
pop ax
ret

restore_keyboard:
push ax
push es
call clear_player_car
cli
mov ax, 0
mov es, ax
mov ax, word [cs:previous_keyboard_isr]
mov [es:9*4], ax
mov ax, word [cs:previous_keyboard_isr+2]
mov [es:9*4+2], ax
sti
pop es
pop ax
ret

restore_timer:
push ax
push es
cli
mov ax, 0
mov es, ax
mov ax, word [cs:previous_timer_isr]
mov [es:8*4], ax
mov ax, word [cs:previous_timer_isr+2]
mov [es:8*4+2], ax
sti
pop es
pop ax
ret

;ENEMY CAR FUNCTIONALITY 
generate_random:
push dx
push cx
push bx
mov ax, [cs:RandomValue]
mov cx, 75
mul cx
add ax, 74
mov [cs:RandomValue], ax
pop bx
pop cx
pop dx
ret

get_random_lane:
push ax
push dx
call generate_random
xor dx, dx
mov cx, 3
div cx
mov bl, dl
pop dx
pop ax
ret

init_enemy_system:
push ax
push bx
mov ah, 0x00
int 0x1A
mov [cs:RandomValue], dx
mov byte [cs:CurrentLane], 0
mov word [cs:EnemyTimer], 0
mov byte [cs:LeftEnemy1Status], 0
mov byte [cs:LeftEnemy2Status], 0
mov byte [cs:MidEnemy1Status], 0
mov byte [cs:MidEnemy2Status], 0
mov byte [cs:RightEnemy1Status], 0
mov byte [cs:RightEnemy2Status], 0
mov byte [cs:BonusStatus], 0
mov word [cs:BonusTimer], bonusDelayt
pop bx
pop ax
ret

spawn_enemies:
push ax
push bx
push cx
mov ax, [cs:EnemyTimer]
cmp ax, 0
jle .attempt_spawn
dec word [cs:EnemyTimer]
jmp .spawn_done
.attempt_spawn:
call get_random_lane
cmp bl, 0
je .try_left
cmp bl, 1
je .try_mid
jmp .try_right
.try_left:
call spawn_left_lane
cmp al, 1
je .spawn_success
jmp .try_another
.try_mid:
call spawn_mid_lane
cmp al, 1
je .spawn_success
jmp .try_another
.try_right:
call spawn_right_lane
cmp al, 1
je .spawn_success
jmp .try_another
.try_another:
call generate_random
and ax, 0x0F
add ax, 5
mov [cs:EnemyTimer], ax
jmp .spawn_done
.spawn_success:
call generate_random
and ax, 0x1F
add ax, ENEMY_DELAY
mov [cs:EnemyTimer], ax
.spawn_done:
pop cx
pop bx
pop ax
ret

spawn_left_lane:
push bx
cmp byte [cs:LeftEnemy1Status], 1
jne .check_slot1
cmp byte [cs:LeftEnemy2Status], 1
jne .check_slot2
mov al, 0
jmp .spawn_complete
.check_slot1:
cmp byte [cs:LeftEnemy2Status], 0
je .verify_horizontal1
mov ax, [cs:LeftEnemy2Pos]
cmp ax, ENEMY_SPACE_VERTICAL
jl .check_slot2
jmp .verify_horizontal1
.check_slot2:
cmp byte [cs:LeftEnemy1Status], 0
je .verify_horizontal2
mov ax, [cs:LeftEnemy1Pos]
cmp ax, ENEMY_SPACE_VERTICAL
jl .spawn_failed
jmp .verify_horizontal2
.verify_horizontal1:
call check_horizontal_space
cmp al, 0
je .check_slot2
mov byte [cs:LeftEnemy1Status], 1
mov word [cs:LeftEnemy1Pos], -6
mov al, 1
jmp .spawn_complete
.verify_horizontal2:
call check_horizontal_space
cmp al, 0
je .spawn_failed
mov byte [cs:LeftEnemy2Status], 1
mov word [cs:LeftEnemy2Pos], -6
mov al, 1
jmp .spawn_complete
.spawn_failed:
mov al, 0
.spawn_complete:
pop bx
ret

spawn_mid_lane:
push bx
cmp byte [cs:MidEnemy1Status], 1
jne .check_slot1
cmp byte [cs:MidEnemy2Status], 1
jne .check_slot2
mov al, 0
jmp .spawn_complete
.check_slot1:
cmp byte [cs:MidEnemy2Status], 0
je .verify_horizontal1
mov ax, [cs:MidEnemy2Pos]
cmp ax, ENEMY_SPACE_VERTICAL
jl .check_slot2
jmp .verify_horizontal1
.check_slot2:
cmp byte [cs:MidEnemy1Status], 0
je .verify_horizontal2
mov ax, [cs:MidEnemy1Pos]
cmp ax, ENEMY_SPACE_VERTICAL
jl .spawn_failed
jmp .verify_horizontal2
.verify_horizontal1:
call check_horizontal_space
cmp al, 0
je .check_slot2
mov byte [cs:MidEnemy1Status], 1
mov word [cs:MidEnemy1Pos], -6
mov al, 1
jmp .spawn_complete
.verify_horizontal2:
call check_horizontal_space
cmp al, 0
je .spawn_failed
mov byte [cs:MidEnemy2Status], 1
mov word [cs:MidEnemy2Pos], -6
mov al, 1
jmp .spawn_complete
.spawn_failed:
mov al, 0
.spawn_complete:
pop bx
ret

spawn_right_lane:
push bx
cmp byte [cs:RightEnemy1Status], 1
jne .check_slot1
cmp byte [cs:RightEnemy2Status], 1
jne .check_slot2
mov al, 0
jmp .spawn_complete
.check_slot1:
cmp byte [cs:RightEnemy2Status], 0
je .verify_horizontal1
mov ax, [cs:RightEnemy2Pos]
cmp ax, ENEMY_SPACE_VERTICAL
jl .check_slot2
jmp .verify_horizontal1
.check_slot2:
cmp byte [cs:RightEnemy1Status], 0
je .verify_horizontal2
mov ax, [cs:RightEnemy1Pos]
cmp ax, ENEMY_SPACE_VERTICAL
jl .spawn_failed
jmp .verify_horizontal2
.verify_horizontal1:
call check_horizontal_space
cmp al, 0
je .check_slot2
mov byte [cs:RightEnemy1Status], 1
mov word [cs:RightEnemy1Pos], -6
mov al, 1
jmp .spawn_complete
.verify_horizontal2:
call check_horizontal_space
cmp al, 0
je .spawn_failed
mov byte [cs:RightEnemy2Status], 1
mov word [cs:RightEnemy2Pos], -6
mov al, 1
jmp .spawn_complete
.spawn_failed:
mov al, 0
.spawn_complete:
pop bx
ret

check_horizontal_space:
push bx
push cx
mov cx, 0
cmp byte [cs:LeftEnemy1Status], 1
jne .check_left2
mov ax, [cs:LeftEnemy1Pos]
cmp ax, ENEMY_SPACE_HORIZONTAL
jge .check_left2
cmp ax, 0
jl .check_left2
inc cx
.check_left2:
cmp byte [cs:LeftEnemy2Status], 1
jne .check_mid1
mov ax, [cs:LeftEnemy2Pos]
cmp ax, ENEMY_SPACE_HORIZONTAL
jge .check_mid1
cmp ax, 0
jl .check_mid1
inc cx
.check_mid1:
cmp byte [cs:MidEnemy1Status], 1
jne .check_mid2
mov ax, [cs:MidEnemy1Pos]
cmp ax, ENEMY_SPACE_HORIZONTAL
jge .check_mid2
cmp ax, 0
jl .check_mid2
inc cx
.check_mid2:
cmp byte [cs:MidEnemy2Status], 1
jne .check_right1
mov ax, [cs:MidEnemy2Pos]
cmp ax, ENEMY_SPACE_HORIZONTAL
jge .check_right1
cmp ax, 0
jl .check_right1
inc cx
.check_right1:
cmp byte [cs:RightEnemy1Status], 1
jne .check_right2
mov ax, [cs:RightEnemy1Pos]
cmp ax, ENEMY_SPACE_HORIZONTAL
jge .check_right2
cmp ax, 0
jl .check_right2
inc cx
.check_right2:
cmp byte [cs:RightEnemy2Status], 1
jne .evaluate_space
mov ax, [cs:RightEnemy2Pos]
cmp ax, ENEMY_SPACE_HORIZONTAL
jge .evaluate_space
cmp ax, 0
jl .evaluate_space
inc cx
.evaluate_space:
cmp cx, 2
jge .space_unavailable
mov al, 1
jmp .space_check_done
.space_unavailable:
mov al, 0
.space_check_done:
pop cx
pop bx
ret

;BONUS SYSTEM 
spawn_bonus:
push ax
push bx
push cx

cmp byte [cs:BonusStatus], 1
je .bonus_done

mov ax, [cs:BonusTimer]
cmp ax, 0
jle .try_bonus_spawn
dec word [cs:BonusTimer]
jmp .bonus_done

.try_bonus_spawn:
mov word [cs:BonusTimer], bonusDelayt

mov cx, 10

.retry_spawn:
call get_random_lane

cmp bl, 0
je .check_left_lane
cmp bl, 1
je .check_mid_lane
jmp .check_right_lane

.check_left_lane:
cmp byte [cs:LeftEnemy1Status], 1
jne .check_left_enemy2
mov ax, [cs:LeftEnemy1Pos]
cmp ax, 14
jl .next_attempt

.check_left_enemy2:
cmp byte [cs:LeftEnemy2Status], 1
jne .left_safe
mov ax, [cs:LeftEnemy2Pos]
cmp ax, 14
jl .next_attempt

.left_safe:
mov byte [cs:BonusLanePos], 0
jmp .create_bonus

.check_mid_lane:
cmp byte [cs:MidEnemy1Status], 1
jne .check_mid_enemy2
mov ax, [cs:MidEnemy1Pos]
cmp ax, 14
jl .next_attempt

.check_mid_enemy2:
cmp byte [cs:MidEnemy2Status], 1
jne .mid_safe
mov ax, [cs:MidEnemy2Pos]
cmp ax, 14
jl .next_attempt

.mid_safe:
mov byte [cs:BonusLanePos], 1
jmp .create_bonus

.check_right_lane:
cmp byte [cs:RightEnemy1Status], 1
jne .check_right_enemy2
mov ax, [cs:RightEnemy1Pos]
cmp ax, 14
jl .next_attempt

.check_right_enemy2:
cmp byte [cs:RightEnemy2Status], 1
jne .right_safe
mov ax, [cs:RightEnemy2Pos]
cmp ax, 14
jl .next_attempt

.right_safe:
mov byte [cs:BonusLanePos], 2
jmp .create_bonus

.next_attempt:
dec cx
jz .bonus_done
jmp .retry_spawn

.create_bonus:
mov word [cs:BonusPosition], -2
mov byte [cs:BonusStatus], 1

.bonus_done:
pop cx
pop bx
pop ax
ret

update_bonus:
push ax
push bx
push cx
push di
cmp byte [cs:BonusStatus], 1
jne .bonus_update_done

call remove_bonus
inc word [cs:BonusPosition]
mov ax, [cs:BonusPosition]

cmp ax, 25
jge .delete_bonus

cmp ax, 18
jl .draw_bonus
cmp ax, 23
jg .draw_bonus

mov al, [cs:current_player_lane]
cmp al, [cs:BonusLanePos]
jne .draw_bonus

call collect_bonus_points
jmp .bonus_update_done

.draw_bonus:
call draw_bonus_item
jmp .bonus_update_done

.delete_bonus:
mov byte [cs:BonusStatus], 0

.bonus_update_done:
pop di
pop cx
pop bx
pop ax
ret

draw_bonus_item:
push ax
push bx
push cx
push di
push es
mov ax, 0xB800
mov es, ax
mov ax, [cs:BonusPosition]
mov bx, 160
mul bx
mov di, ax
mov al, [cs:BonusLanePos]
cmp al, 0
je .left_lane
cmp al, 1
je .mid_lane
add di, rightLane + 4
jmp .draw_icon
.left_lane:
add di, leftLane + 4
jmp .draw_icon
.mid_lane:
add di, midLane + 4
.draw_icon:
mov ax, 0x7624
mov [es:di], ax
pop es
pop di
pop cx
pop bx
pop ax
ret

remove_bonus:
push ax
push bx
push cx
push di
push es
mov ax, 0xB800
mov es, ax
mov ax, [cs:BonusPosition]
mov bx, 160
mul bx
mov di, ax
mov al, [cs:BonusLanePos]
cmp al, 0
je .clear_left
cmp al, 1
je .clear_mid
add di, rightLane + 4
jmp .clear_position
.clear_left:
add di, leftLane + 4
jmp .clear_position
.clear_mid:
add di, midLane + 4
.clear_position:
mov ax, 0x7720
mov [es:di], ax
pop es
pop di
pop cx
pop bx
pop ax
ret

check_bonus_collision:
push ax
push bx
mov al, [cs:current_player_lane]
cmp al, [cs:BonusLanePos]
jne .no_collision
mov ax, [cs:BonusPosition]
cmp ax, 20
jl .no_collision
cmp ax, 25
jg .no_collision
call collect_bonus_points
.no_collision:
pop bx
pop ax
ret

collect_bonus_points:
push ax
mov ax, [cs:player_score]
add ax, BONUS_POINTS
mov [cs:player_score], ax

mov byte [cs:BonusStatus], 0
mov byte [cs:bonus_flag], 1

call update_score_display
pop ax
ret
 
update_enemies:
push ax
push bx
push cx
call clear_all_enemies
cmp byte [cs:LeftEnemy1Status], 1
jne .skip_left1
inc word [cs:LeftEnemy1Pos]
mov ax, [cs:LeftEnemy1Pos]
cmp ax, 25
jge .remove_left1
mov bx, leftLane
mov cx, ax
call draw_enemy_car
jmp .skip_left1
.remove_left1:
mov byte [cs:LeftEnemy1Status], 0
call add_score
.skip_left1:
cmp byte [cs:LeftEnemy2Status], 1
jne .skip_left2
inc word [cs:LeftEnemy2Pos]
mov ax, [cs:LeftEnemy2Pos]
cmp ax, 25
jge .remove_left2
mov bx, leftLane
mov cx, ax
call draw_enemy_car
jmp .skip_left2
.remove_left2:
mov byte [cs:LeftEnemy2Status], 0
call add_score
.skip_left2:
cmp byte [cs:MidEnemy1Status], 1
jne .skip_mid1
inc word [cs:MidEnemy1Pos]
mov ax, [cs:MidEnemy1Pos]
cmp ax, 25
jge .remove_mid1
mov bx, midLane
mov cx, ax
call draw_enemy_car
jmp .skip_mid1
.remove_mid1:
mov byte [cs:MidEnemy1Status], 0
call add_score
.skip_mid1:
cmp byte [cs:MidEnemy2Status], 1
jne .skip_mid2
inc word [cs:MidEnemy2Pos]
mov ax, [cs:MidEnemy2Pos]
cmp ax, 25
jge .remove_mid2
mov bx, midLane
mov cx, ax
call draw_enemy_car
jmp .skip_mid2
.remove_mid2:
mov byte [cs:MidEnemy2Status], 0
call add_score
.skip_mid2:
cmp byte [cs:RightEnemy1Status], 1
jne .skip_right1
inc word [cs:RightEnemy1Pos]
mov ax, [cs:RightEnemy1Pos]
cmp ax, 25
jge .remove_right1
mov bx, rightLane
mov cx, ax
call draw_enemy_car
jmp .skip_right1
.remove_right1:
mov byte [cs:RightEnemy1Status], 0
call add_score
.skip_right1:
cmp byte [cs:RightEnemy2Status], 1
jne .skip_right2
inc word [cs:RightEnemy2Pos]
mov ax, [cs:RightEnemy2Pos]
cmp ax, 25
jge .remove_right2
mov bx, rightLane
mov cx, ax
call draw_enemy_car
jmp .skip_right2
.remove_right2:
mov byte [cs:RightEnemy2Status], 0
call add_score
.skip_right2:
call spawn_bonus
call update_bonus
pop cx
pop bx
pop ax
ret

draw_enemy_car:
push ax
push bx
push cx
push dx
push di
mov ax, cx
mov dx, 160
mul dx
add ax, bx
mov di, ax
cmp bx, leftLane
je .red_car
cmp bx, midLane
je .blue_car
push di
push 0x5C20
call drawCar
jmp .draw_done
.red_car:
push di
push 0x4C20
call drawCar
jmp .draw_done
.blue_car:
push di
push 0x1C20
call drawCar
.draw_done:
pop di
pop dx
pop cx
pop bx
pop ax
ret

clear_all_enemies:
push ax
push bx
push cx
push dx
push di
cmp byte [cs:LeftEnemy1Status], 1
jne .skip_left1
mov ax, [cs:LeftEnemy1Pos]
cmp ax, 0
jl .skip_left1
cmp ax, 24
jg .skip_left1
mov bx, leftLane
mov cx, ax
call clear_car_position
.skip_left1:
cmp byte [cs:LeftEnemy2Status], 1
jne .skip_left2
mov ax, [cs:LeftEnemy2Pos]
cmp ax, 0
jl .skip_left2
cmp ax, 24
jg .skip_left2
mov bx, leftLane
mov cx, ax
call clear_car_position
.skip_left2:
cmp byte [cs:MidEnemy1Status], 1
jne .skip_mid1
mov ax, [cs:MidEnemy1Pos]
cmp ax, 0
jl .skip_mid1
cmp ax, 24
jg .skip_mid1
mov bx, midLane
mov cx, ax
call clear_car_position
.skip_mid1:
cmp byte [cs:MidEnemy2Status], 1
jne .skip_mid2
mov ax, [cs:MidEnemy2Pos]
cmp ax, 0
jl .skip_mid2
cmp ax, 24
jg .skip_mid2
mov bx, midLane
mov cx, ax
call clear_car_position
.skip_mid2:
cmp byte [cs:RightEnemy1Status], 1
jne .skip_right1
mov ax, [cs:RightEnemy1Pos]
cmp ax, 0
jl .skip_right1
cmp ax, 24
jg .skip_right1
mov bx, rightLane
mov cx, ax
call clear_car_position
.skip_right1:
cmp byte [cs:RightEnemy2Status], 1
jne .clear_done
mov ax, [cs:RightEnemy2Pos]
cmp ax, 0
jl .clear_done
cmp ax, 24
jg .clear_done
mov bx, rightLane
mov cx, ax
call clear_car_position
.clear_done:
pop di
pop dx
pop cx
pop bx
pop ax
ret

clear_car_position:
push ax
push bx
push cx
push dx
push di
push si
mov dx, cx
mov ax, dx
mov cx, 160
mul cx
add ax, bx
mov di, ax
mov ax, 0x7720
push di
add word [esp], 960
push 7
push ax
call draw
push di
add word [esp], 804
push 3
push ax
call draw
mov si, di
add si, 810
mov word [es:si], 0x7720
mov si, di
add si, 802
mov word [es:si], 0x7720
push di
add word [esp], 800
push 1
push ax
call draw
push di
add word [esp], 812
push 1
push ax
call draw
push di
add word [esp], 642
push 5
push ax
call draw
push di
add word [esp], 482
push 5
push ax
call draw
push di
add word [esp], 486
push 1
push ax
call draw
push di
add word [esp], 322
push 5
push ax
call draw
push di
add word [esp], 164
push 3
push ax
call draw
mov si, di
add si, 170
mov word [es:si], 0x7720
mov si, di
add si, 162
mov word [es:si], 0x7720
push di
add word [esp], 160
push 1
push ax
call draw
push di
add word [esp], 172
push 1
push ax
call draw
push di
push 7
push ax
call draw
pop si
pop di
pop dx
pop cx
pop bx
pop ax
ret

add_score:
push ax
mov ax, [cs:player_score]
inc ax
mov [cs:player_score], ax
call update_score_display
pop ax
ret

;HANDLING COLLISION 
check_collisions:
push ax
push bx
push cx
push dx
mov cx, 24
cmp byte [cs:current_player_lane], 0
jne .check_mid
cmp byte [cs:LeftEnemy1Status], 1
jne .check_left2
mov ax, [cs:LeftEnemy1Pos]
call check_car_overlap
cmp ax, 1
je .collision_detected
.check_left2:
cmp byte [cs:LeftEnemy2Status], 1
jne .no_collision
mov ax, [cs:LeftEnemy2Pos]
call check_car_overlap
cmp ax, 1
je .collision_detected
jmp .no_collision
.check_mid:
cmp byte [cs:current_player_lane], 1
jne .check_right
cmp byte [cs:MidEnemy1Status], 1
jne .check_mid2
mov ax, [cs:MidEnemy1Pos]
call check_car_overlap
cmp ax, 1
je .collision_detected
.check_mid2:
cmp byte [cs:MidEnemy2Status], 1
jne .no_collision
mov ax, [cs:MidEnemy2Pos]
call check_car_overlap
cmp ax, 1
je .collision_detected
jmp .no_collision
.check_right:
cmp byte [cs:RightEnemy1Status], 1
jne .check_right2
mov ax, [cs:RightEnemy1Pos]
call check_car_overlap
cmp ax, 1
je .collision_detected
.check_right2:
cmp byte [cs:RightEnemy2Status], 1
jne .no_collision
mov ax, [cs:RightEnemy2Pos]
call check_car_overlap
cmp ax, 1
je .collision_detected
jmp .no_collision
.collision_detected:
mov byte [cs:game_over_flag], 1
.no_collision:
pop dx
pop cx
pop bx
pop ax
ret

check_car_overlap:
push bx
push cx
mov bx, ax
mov ax, bx
add ax, 7
cmp ax, 19
jl .no_overlap
cmp bx, 24
jg .no_overlap
mov ax, 1
jmp .overlap_done
.no_overlap:
mov ax, 0
.overlap_done:
pop cx
pop bx
ret

;MAIN GAME LOOP 
scrolldown_cyclic:
push bp
mov bp, sp
push ax
push bx
push cx
push si
push di
push ds
push es
mov ax, cs
mov ds, ax

game_cycle:
cmp byte [game_over_flag], 1
je exit_game
cmp byte [game_paused], 1
je .check_scrolling
cmp byte [scroll_active], 1
jne game_cycle
mov byte [scroll_active], 0

.check_scrolling:
cmp byte [game_paused], 1
je game_cycle

call wait_vsync

call clear_player_car
call clear_all_enemies
mov ax, 0B800h
mov ds, ax
mov es, ax
mov ax, 9000h
mov es, ax
mov ax, 0B800h
mov ds, ax
mov cx, 1920
mov si, 160
xor di, di
cld
rep movsw
mov ax, 0B800h
mov es, ax
mov ax, 9000h
mov ds, ax
mov si, 3680
mov di, 160
mov cx, 80
cld
rep movsw
xor si, si
mov di, 320
mov cx, 1840
cld
rep movsw
call spawn_enemies
call update_enemies
call check_collisions
mov ax, 0B800h
mov es, ax

mov di, 20*2
mov ax, 0x7720
mov cx, 38
rep stosw

mov di, (20-1)*2
mov word [es:di], 0x00DB
mov di, 20*2
mov word [es:di], 0x7EDB
mov di, (20+1)*2
mov word [es:di], 0x00DB

mov di, (58-1)*2
mov word [es:di], 0x00DB
mov di, 58*2
mov word [es:di], 0x7EDB
mov di, (58+1)*2
mov word [es:di], 0x00DB
push 32
push 0x7F7C
call draw_road_marker
push 45
push 0x7F7C
call draw_road_marker
mov ax, cs
mov ds, ax
cmp byte [game_over_flag], 1
je skip_score_update
add word [player_score], 1
skip_score_update:
mov ax, cs
mov ds, ax
cmp byte [game_over_flag], 1
je exit_game
call clear_player_car
push word [player_location]
push 0x4520
call drawCar
call update_score_display
jmp game_cycle

exit_game:
pop es
pop ds
pop di
pop si
pop cx
pop bx
pop ax
pop bp
ret 2

;SCOREEEE 
update_score_display:
push ax
push bx
push cx
push dx
push si
push di
push es
push ds
mov ax, 0B800h
mov es, ax
mov di, 0
mov ax, 0x2020
mov cx, 19
rep stosw
mov di, 0
mov word [es:di], 0x2F53
add di, 2
mov word [es:di], 0x2F43
add di, 2
mov word [es:di], 0x2F4F
add di, 2
mov word [es:di], 0x2F52
add di, 2
mov word [es:di], 0x2F45
add di, 2
mov word [es:di], 0x2F3A
add di, 2
mov word [es:di], 0x2F20
add di, 2
push cs
pop ds
mov ax, [player_score]
xor cx, cx
cmp ax, 0
jne score_not_zero
mov word [es:di], 0x2F30
add di, 2
jmp score_display_done
score_not_zero:
mov bx, 10
score_convert:
xor dx, dx
div bx
add dl, '0'
push dx
inc cx
cmp ax, 0
jne score_convert
score_display:
pop dx
mov al, dl
mov ah, 0x2F
mov word [es:di], ax
add di, 2
loop score_display
score_display_done:
pop ds
pop es
pop di
pop si
pop dx
pop cx
pop bx
pop ax
ret

;GAME OVER SCREEN 
show_game_over:
push ax
push bx
push cx
push di
push es
push ds
mov ax, 0B800h
mov es, ax
mov di, 0
mov ax, 0x4720
mov cx, 2000
rep stosw
mov di, 1824
mov word [es:di], 0x4F47
add di, 2
mov word [es:di], 0x4F41
add di, 2
mov word [es:di], 0x4F4D
add di, 2
mov word [es:di], 0x4F45
add di, 2
mov word [es:di], 0x4F20
add di, 2
mov word [es:di], 0x4F4F
add di, 2
mov word [es:di], 0x4F56
add di, 2
mov word [es:di], 0x4F45
add di, 2
mov word [es:di], 0x4F52
mov di, 1984
mov word [es:di], 0x4F46
add di, 2
mov word [es:di], 0x4F49
add di, 2
mov word [es:di], 0x4F4E
add di, 2
mov word [es:di], 0x4F41
add di, 2
mov word [es:di], 0x4F4C
add di, 2
mov word [es:di], 0x4F20
add di, 2
mov word [es:di], 0x4F53
add di, 2
mov word [es:di], 0x4F43
add di, 2
mov word [es:di], 0x4F4F
add di, 2
mov word [es:di], 0x4F52
add di, 2
mov word [es:di], 0x4F45
add di, 2
mov word [es:di], 0x4F3A
add di, 2
mov word [es:di], 0x4F20
push cs
pop ds
mov ax, [player_score]
xor cx, cx
cmp ax, 0
jne game_over_not_zero
mov word [es:di], 0x4F30
jmp game_over_wait
game_over_not_zero:
mov bx, 10
game_over_convert:
xor dx, dx
div bx
add dl, '0'
push dx
inc cx
cmp ax, 0
jne game_over_convert
game_over_display:
pop dx
mov al, dl
mov ah, 0x4F
mov word [es:di], ax
add di, 2
loop game_over_display
game_over_wait:
mov ah, 0
int 16h
pop ds
pop es
pop di
pop cx
pop bx
pop ax
ret

;CLEAR PLAYER CAR 
clear_player_car:
push ax
push cx
push di
push es
mov ax, 0B800h
mov es, ax
mov ax, 0x7720
mov di, [cs:player_location]
add di, 960
push di
push 7
push ax
call draw
mov di, [cs:player_location]
add di, 804
push di
push 3
push ax
call draw
mov di, [cs:player_location]
add di, 810
mov word [es:di], 0x7720
mov di, [cs:player_location]
add di, 802
mov word [es:di], 0x7720
mov di, [cs:player_location]
add di, 800
push di
push 1
push ax
call draw
mov di, [cs:player_location]
add di, 812
push di
push 1
push ax
call draw
mov di, [cs:player_location]
add di, 642
push di
push 5
push ax
call draw
mov di, [cs:player_location]
add di, 482
push di
push 5
push ax
call draw
mov di, [cs:player_location]
add di, 486
push di
push 1
push ax
call draw
mov di, [cs:player_location]
add di, 322
push di
push 5
push ax
call draw
mov di, [cs:player_location]
add di, 164
push di
push 3
push ax
call draw
mov di, [cs:player_location]
add di, 170
mov word [es:di], 0x7720
mov di, [cs:player_location]
add di, 162
mov word [es:di], 0x7720
mov di, [cs:player_location]
add di, 160
push di
push 1
push ax
call draw
mov di, [cs:player_location]
add di, 172
push di
push 1
push ax
call draw
mov di, [cs:player_location]
push di
push 7
push ax
call draw
pop es
pop di
pop cx
pop ax
ret


delay:
push bx
mov bx, 0x3FFF
.delay_loop:
dec bx
jnz .delay_loop
pop bx
ret

draw:
push bp
mov bp, sp
push es
push di
push cx
mov ax, 0B800h
mov es, ax
mov di, [bp+8]
mov ax, [bp+4]
mov cx, [bp+6]
rep stosw
pop cx
pop di
pop es
pop bp
ret 6

drawCar:
push bp
mov bp, sp
push ax
push bx
push cx
push di
push es
mov ax, 0B800h
mov es, ax
mov dx, [bp+4]
mov bx, [bp+6]
mov ax, bx
add ax, 960
push ax
push 7
push dx
call draw
mov ax, bx
add ax, 804
push ax
push 3
push dx
call draw
mov ax, bx
add ax, 810
mov di, ax
mov ax, 0x702D
stosw
mov ax, bx
add ax, 802
mov di, ax
mov ax, 0x702D
stosw
mov ax, bx
add ax, 800
push ax
push 1
push 0x0720
call draw
mov ax, bx
add ax, 812
push ax
push 1
push 0x0720
call draw
mov ax, bx
add ax, 642
push ax
push 5
push dx
call draw
mov ax, bx
add ax, 482
push ax
push 5
push dx
call draw
mov ax, bx
add ax, 486
push ax
push 1
push 0x0720
call draw
mov ax, bx
add ax, 322
push ax
push 5
push dx
call draw
mov ax, bx
add ax, 164
push ax
push 3
push dx
call draw
mov ax, bx
add ax, 170
mov di, ax
mov ax, 0x702D
stosw
mov ax, bx
add ax, 162
mov di, ax
mov ax, 0x702D
stosw
mov ax, bx
add ax, 160
push ax
push 1
push 0x0720
call draw
mov ax, bx
add ax, 172
push ax
push 1
push 0x0720
call draw
push bx
push 7
push dx
call draw
pop es
pop di
pop cx
pop bx
pop ax
pop bp
ret 4

draw_tree:
push bp
mov bp, sp
mov ax, 0B800h
mov es, ax
mov si, [bp+4]
mov ax, 0x2A1E
mov di, si
mov cx, 1
rep stosw
mov di, si
add di, 160
sub di, 2
mov cx, 3
rep stosw
mov di, si
add di, 320
sub di, 4
mov cx, 5
rep stosw
mov ah, 0x26
mov al, 124
mov di, si
add di, 480
stosw
pop bp
ret 2

draw_footpath:
push bp
mov bp, sp
push ax
push bx
push cx
push di
push si
push es
mov ax, 0xB800
mov es, ax
mov bx, 80

mov cx, 25
xor si, si
.left_border:
mov ax, si
mul bx
add ax, [bp+4]
dec ax
shl ax, 1
mov di, ax
mov word [es:di], 0x00DB
inc si
loop .left_border

mov cx, 25
xor si, si
.footpath:
mov ax, si
mul bx
add ax, [bp+4]
shl ax, 1
mov di, ax
mov word [es:di], 0x7EDB
inc si
loop .footpath

mov cx, 25
xor si, si
.right_border:
mov ax, si
mul bx
add ax, [bp+4]
inc ax
shl ax, 1
mov di, ax
mov word [es:di], 0x00DB
inc si
loop .right_border

pop es
pop si
pop di
pop cx
pop bx
pop ax
pop bp
ret 2

draw_landscape:
push bp
mov bp, sp
push ax
push bx
push cx
push di
mov bx, [bp+4]
mov di, [bp+6]
mov cx, 25
.landscape_loop:
push ax
push cx
push di
mov ax, 0x2020
mov cx, bx
rep stosw
pop di
pop cx
pop ax
add di, 160
dec cx
jnz .landscape_loop
pop di
pop cx
pop bx
pop ax
pop bp
ret 4

draw_road_marker:
push bp
mov bp, sp
push ax
push bx
push cx
push di
push si
mov bx, 80
mov cx, 25
xor si, si
.marker_loop:
mov ax, si
mul bx
add ax, [bp+6]
shl ax, 1
mov di, ax
mov ax, [bp+4]
mov [es:di], ax
inc si
loop .marker_loop
pop si
pop di
pop cx
pop bx
pop ax
pop bp
ret 4

;Intro screen 
show_intro:
push ax
push bx
push cx
push dx
push si
push di
push es
push ds

call clear_display

push 0x0E
push 30
push 9
push intro_message1
call display_string

push 0x0C
push 27
push 11
push intro_message2
call display_string

push 0x0A
push 30
push 13
push intro_message3
call display_string

mov cx, 0x0030
mov dx, 0x0000
mov ah, 0x86
int 0x15

pop ds
pop es
pop di
pop si
pop dx
pop cx
pop bx
pop ax
ret

;cover page 
show_cover:
push ax
push bx
push cx
push dx
push si
push di
push es
push ds

call clear_display
call draw_frame

push 0x0E
push 18
push 6
push creator_names
call display_string

push 0x0F
push 30
push 8
push section_text
call display_string

push 0x0C
push 33
push 11
push game_title
call display_string

push 0x0B
push 35
push 13
push loading_text
call display_string

push 0x0E
push 27
push 24
push key_prompt
call display_string

xor cx, cx
.animation_loop:
push cx
call update_progress_bar
push cx
call show_percentage
call delay
inc cx
cmp cx, 101
jne .animation_loop

mov ah, 0x00
int 0x16

pop ds
pop es
pop di
pop si
pop dx
pop cx
pop bx
pop ax
ret


intro_message1: db 'WELCOME TO', 0
intro_message2: db 'RACECAR GAME 2025', 0
intro_message3: db 'GET READY!', 0
 
start:
call show_intro

call show_cover

mov ax, 10000
out 0x40, al
mov al, ah
out 0x40, al
mov byte [cs:game_over_flag], 0
mov byte [cs:bonus_flag], 0
mov byte [cs:game_paused], 0
mov word [cs:player_score], 0
mov word [cs:player_location], 2792
mov byte [cs:current_player_lane], 1
mov byte [cs:scroll_active], 0
mov word [cs:time_counter], 0
mov word [cs:game_speed], 5
call init_enemy_system
call setup_keyboard
call setup_timer

mov ax, 0B800h
mov es, ax
mov di, 0
mov ax, 0x7720
mov cx, 2000
rep stosw

push 20
call draw_footpath
push 58
call draw_footpath
push 0
push 19

mov ax, 0xB800
mov es, ax
mov di, (20-1)*2
mov word [es:di], 0x00DB
mov di, 20*2
mov word [es:di], 0x7EDB
mov di, (20+1)*2
mov word [es:di], 0x00DB
mov di, (58-1)*2
mov word [es:di], 0x00DB
mov di, 58*2
mov word [es:di], 0x7EDB
mov di, (58+1)*2
mov word [es:di], 0x00DB

call draw_landscape
push 120
push 21
call draw_landscape
push 32
push 0x7F7C
call draw_road_marker
push 45
push 0x7F7C
call draw_road_marker

push 778
call draw_tree
push 782
call draw_tree
push 1624
call draw_tree
push 1618
call draw_tree
push 3030
call draw_tree
push 168
call draw_tree
push 3048
call draw_tree
push 1888
call draw_tree
push 1894
call draw_tree

push word [cs:player_location]
push 0x4520
call drawCar
call update_score_display

mov ax, 5
push ax
call scrolldown_cyclic

cmp byte [cs:game_over_flag], 1
jne .terminateProgram
call show_game_over

.terminateProgram:
call restore_keyboard
call restore_timer
mov ax, 0x4C00
int 0x21