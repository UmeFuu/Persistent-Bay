// The lighting system
//
// consists of light fixtures (/obj/machinery/light) and light tube/bulb items (/obj/item/weapon/light)


// status values shared between lighting fixtures and items
#define LIGHT_OK 0
#define LIGHT_EMPTY 1
#define LIGHT_BROKEN 2
#define LIGHT_BURNED 3

#define LIGHT_BULB_TEMPERATURE 400 //K - used value for a 60W bulb
#define LIGHTING_POWER_FACTOR 5		//5W per luminosity * range


#define LIGHTMODE_EMERGENCY "emergency_lighting"
#define LIGHTMODE_READY "ready"

/obj/machinery/light_construct
	name = "light fixture frame"
	desc = "A light fixture under construction."
	icon = 'icons/obj/lighting.dmi'
	icon_state = "tube-construct-stage1"
	anchored = TRUE
	plane = ABOVE_HUMAN_PLANE
	layer = ABOVE_HUMAN_LAYER

	var/stage = 1
	var/fixture_type = /obj/machinery/light
	var/sheets_refunded = 2

/obj/machinery/light_construct/New(atom/newloc, var/newdir, atom/fixture = null)
	..(newloc)

	if(newdir)
		set_dir(newdir)

	if(istype(fixture))
		if(istype(fixture, /obj/machinery/light))
			fixture_type = fixture.type
		fixture.transfer_fingerprints_to(src)
		stage = 1

	update_icon()

/obj/machinery/light_construct/update_icon()
	switch(stage)
		if(1) icon_state = "tube-construct-stage1"
		if(2) icon_state = "tube-construct-stage2"
		if(3) icon_state = "tube-empty"

/obj/machinery/light_construct/examine(mob/user)
	if(!..(user, 2))
		return

	switch(src.stage)
		if(1) to_chat(user, "It's an empty frame.")
		if(2) to_chat(user, "It's wired.")
		if(3) to_chat(user, "The casing is closed.")

/obj/machinery/light_construct/attackby(obj/item/weapon/W as obj, mob/user as mob)
	src.add_fingerprint(user)
	if(isWrench(W))
		if (src.stage == 1)
			playsound(src.loc, 'sound/items/Ratchet.ogg', 75, 1)
			to_chat(usr, "You begin deconstructing \a [src].")
			if (!do_after(usr, 30,src))
				return
			new /obj/item/stack/material/steel( get_turf(src.loc), sheets_refunded )
			user.visible_message("[user.name] deconstructs [src].", \
				"You deconstruct [src].", "You hear a noise.")
			playsound(src.loc, 'sound/items/Deconstruct.ogg', 75, 1)
			qdel(src)
		if (src.stage == 2)
			to_chat(usr, "You have to remove the wires first.")
			return

		if (src.stage == 3)
			to_chat(usr, "You have to unscrew the case first.")
			return

	if(isWirecutter(W))
		if (src.stage != 2) return
		src.stage = 1
		src.update_icon()
		new /obj/item/stack/cable_coil(get_turf(src.loc), 1, "red")
		user.visible_message("[user.name] removes the wiring from [src].", \
			"You remove the wiring from [src].", "You hear a noise.")
		playsound(src.loc, 'sound/items/Wirecutter.ogg', 100, 1)
		return

	if(istype(W, /obj/item/stack/cable_coil))
		if (src.stage != 1) return
		var/obj/item/stack/cable_coil/coil = W
		if (coil.use(1))
			src.stage = 2
			src.update_icon()
			user.visible_message("[user.name] adds wires to [src].", \
				"You add wires to [src].")
		return

	if(isScrewdriver(W))
		if (src.stage == 2)
			src.stage = 3
			src.update_icon()
			user.visible_message("[user.name] closes [src]'s casing.", \
				"You close [src]'s casing.", "You hear a noise.")
			playsound(src.loc, 'sound/items/Screwdriver.ogg', 75, 1)

			var/obj/machinery/light/newlight = new fixture_type(src.loc, src)
			newlight.set_dir(src.dir)

			src.transfer_fingerprints_to(newlight)
			qdel(src)
			return
	..()

/obj/machinery/light_construct/small
	name = "small light fixture frame"
	desc = "A small light fixture under construction."
	icon = 'icons/obj/lighting.dmi'
	icon_state = "bulb-construct-stage1"
	anchored = TRUE
	plane = ABOVE_HUMAN_PLANE
	layer = ABOVE_HUMAN_LAYER
	stage = 1
	fixture_type = /obj/machinery/light/small
	sheets_refunded = 1

/obj/machinery/light_construct/small/update_icon()
	switch(stage)
		if(1) icon_state = "bulb-construct-stage1"
		if(2) icon_state = "bulb-construct-stage2"
		if(3) icon_state = "bulb-empty"

// the standard tube light fixture
/obj/machinery/light
	name = "light fixture"
	icon = 'icons/obj/lighting.dmi'
	icon_state = "tube1"
	desc = "A lighting fixture."
	anchored = TRUE
	plane = ABOVE_HUMAN_PLANE
	layer = ABOVE_HUMAN_LAYER  					// They were appearing under mobs which is a little weird - Ostaf
	use_power = POWER_USE_ACTIVE
	idle_power_usage = 2
	active_power_usage = 20
	power_channel = LIGHT //Lights are calc'd via area so they dont need to be in the machine list
	frame_type = /obj/machinery/light_construct

	var/base_state = "tube"		// base description and icon_state
	var/flickering = 0
	var/light_type = /obj/item/weapon/light/tube		// the type of light item
	var/datum/effect/effect/system/spark_spread/sparks = new /datum/effect/effect/system/spark_spread
	var/obj/item/weapon/light/lightbulb
	var/current_mode = null

// the smaller bulb light fixture
/obj/machinery/light/small
	icon_state = "bulb1"
	base_state = "bulb"
	desc = "A small lighting fixture."
	light_type = /obj/item/weapon/light/bulb
	frame_type = /obj/machinery/light_construct/small

/obj/machinery/light/small/emergency
	light_type = /obj/item/weapon/light/bulb/red

/obj/machinery/light/small/red
	light_type = /obj/item/weapon/light/bulb/red

/obj/machinery/light/spot
	name = "spotlight"
	desc = "A more robust socket for light tubes that demand more power."
	light_type = /obj/item/weapon/light/tube/large

//-----------------------------------------
// Light Fixture
//-----------------------------------------
// create a new lighting fixture
/obj/machinery/light/New(atom/newloc, obj/machinery/light_construct/construct = null)
	..(newloc)
	if(construct)
		frame_type = construct.type
		construct.transfer_fingerprints_to(src)
		set_dir(construct.dir)
	else 
		lightbulb = new light_type(src)

/obj/machinery/light/Initialize(mapload, d)
	. = ..()
	sparks.set_up(1, 1, src)
	update_icon()
	update_lighting()

/obj/machinery/light/Destroy()
	QDEL_NULL(lightbulb)
	QDEL_NULL(sparks)
	. = ..()

/obj/machinery/light/update_icon()
	pixel_y = 0
	pixel_x = 0
	var/turf/T = get_step(get_turf(src), src.dir)
	if(istype(T, /turf/simulated/wall))
		if(src.dir == NORTH)
			pixel_y = 21
		else if(src.dir == EAST)
			pixel_x = 10
		else if(src.dir == WEST)
			pixel_x = -10

	switch(get_status())		// set icon_states
		if(LIGHT_OK)
			icon_state = "[base_state][!isoff()]"
		if(LIGHT_EMPTY)
			icon_state = "[base_state]-empty"
		if(LIGHT_BURNED)
			icon_state = "[base_state]-burned"
		if(LIGHT_BROKEN)
			icon_state = "[base_state]-broken"

/obj/machinery/light/proc/update_lighting(var/play_effects = TRUE)
	if(!isoff() && get_status() == LIGHT_OK)
		var/changed = 0
		if(current_mode && (current_mode in lightbulb.lighting_modes))
			changed = set_light(arglist(lightbulb.lighting_modes[current_mode]))
		else
			changed = set_light(lightbulb.brightness_range, lightbulb.brightness_power, lightbulb.brightness_color)

		if(changed)
			if(play_effects)
				lightbulb.switch_on()
			active_power_usage = ((light_range * light_power) * LIGHTING_POWER_FACTOR)
	else
		set_light(0)
		active_power_usage = 0

/obj/machinery/light/proc/get_status()
	if(!lightbulb)
		return LIGHT_EMPTY
	else
		return lightbulb.status

// /obj/machinery/light/proc/switch_check()
// 	lightbulb.switch_on()
// 	if(get_status() != LIGHT_OK)
// 		set_light(0)

/obj/machinery/light/attack_generic(var/mob/user, var/damage)
	if(!damage)
		return
	var/status = get_status()
	if(status == LIGHT_EMPTY || status == LIGHT_BROKEN)
		to_chat(user, "That object is useless to you.")
		return
	if(!(status == LIGHT_OK||status == LIGHT_BURNED))
		return
	visible_message("<span class='danger'>[user] smashes the light!</span>")
	attack_animation(user)
	broken()
	return 1

/obj/machinery/light/proc/set_mode(var/new_mode)
	if(current_mode != new_mode)
		current_mode = new_mode
		update_icon()
		update_lighting(FALSE)

/obj/machinery/light/proc/set_emergency_lighting(var/enable)
	if(enable)
		if(LIGHTMODE_EMERGENCY in lightbulb.lighting_modes)
			set_mode(LIGHTMODE_EMERGENCY)
			power_channel = ENVIRON
	else
		if(current_mode == LIGHTMODE_EMERGENCY)
			set_mode(null)
			power_channel = initial(power_channel)


// examine verb
/obj/machinery/light/examine(mob/user)
	. = ..()
	var/fitting = get_fitting_name()
	switch(get_status())
		if(LIGHT_OK)
			to_chat(user, "[desc] It is turned [!isoff()? "on" : "off"].")
		if(LIGHT_EMPTY)
			to_chat(user, "[desc] The [fitting] has been removed.")
		if(LIGHT_BURNED)
			to_chat(user, "[desc] The [fitting] is burnt out.")
		if(LIGHT_BROKEN)
			to_chat(user, "[desc] The [fitting] has been smashed.")

/obj/machinery/light/proc/get_fitting_name()
	var/obj/item/weapon/light/L = light_type
	return initial(L.name)

// attack with item - insert light (if right type), otherwise try to break the light

/obj/machinery/light/proc/insert_bulb(obj/item/weapon/light/L)
	L.forceMove(src)
	lightbulb = L
	update_icon()
	update_lighting()

/obj/machinery/light/proc/remove_bulb()
	. = lightbulb
	lightbulb.dropInto(loc)
	lightbulb.update_icon()
	lightbulb = null
	update_icon()
	update_lighting()

/obj/machinery/light/attackby(obj/item/W, mob/user)
	//Light replacer code
	if(istype(W, /obj/item/device/lightreplacer))
		var/obj/item/device/lightreplacer/LR = W
		if(isliving(user))
			var/mob/living/U = user
			LR.ReplaceLight(src, U)
			return
	// attempt to insert light
	if(istype(W, /obj/item/weapon/light))
		if(lightbulb)
			to_chat(user, "There is a [get_fitting_name()] already inserted.")
			return
		if(!istype(W, light_type))
			to_chat(user, "This type of light requires a [get_fitting_name()].")
			return

		to_chat(user, "You insert [W].")
		user.drop_item()
		insert_bulb(W)
		src.add_fingerprint(user)

		// attempt to break the light
		//If xenos decide they want to smash a light bulb with a toolbox, who am I to stop them? /N

	else if(lightbulb && (lightbulb.status != LIGHT_BROKEN))
		if(prob(1 + W.force * 5))
			user.visible_message("<span class='warning'>[user.name] smashed the light!</span>", "<span class='warning'>You smash the light!</span>", "You hear a tinkle of breaking glass")
			if(!isoff() && (W.obj_flags & OBJ_FLAG_CONDUCTIBLE))
				if (prob(12))
					electrocute_mob(user, get_area(src), src, 0.3)
			broken()
		else
			to_chat(user, "You hit the light!")

	// attempt to stick weapon into light socket
	else if(!lightbulb)
		if(isScrewdriver(W)) //If it's a screwdriver open it.
			playsound(src.loc, 'sound/items/Screwdriver.ogg', 75, 1)
			var/obj/item/weapon/tool/T
			if(T.use_tool(user, src, 1 SECOND))
				user.visible_message("[user.name] opens [src]'s casing.", "You open [src]'s casing.", "You hear a noise.")
				dismantle()
				return

		to_chat(user, "You stick \the [W] into the light socket!")
		if(powered() && (W.obj_flags & OBJ_FLAG_CONDUCTIBLE))
			var/datum/effect/effect/system/spark_spread/s = new /datum/effect/effect/system/spark_spread
			s.set_up(3, 1, src)
			s.start()
			if (prob(75))
				electrocute_mob(user, get_area(src), src, rand(0.7,1.0))

/obj/machinery/light/dismantle()
	new frame_type(src.loc, src.dir, src)
	qdel(src)

// returns whether this light has power
// true if area has power and lightswitch is on
/obj/machinery/light/powered()
	var/area/A = get_area(src)
	return A && A.lightswitch && ..(power_channel)

// called when area power state changes
/obj/machinery/light/power_change()
	spawn(10)
		if(powered())
			turn_on()
		else
			turn_off()
		update_lighting()

/obj/machinery/light/proc/flicker(var/amount = rand(10, 20))
	if(flickering) 
		return
	flickering = TRUE
	spawn(0)
		if(!isoff() && get_status() == LIGHT_OK)
			for(var/i = 0; i < amount; i++)
				if(get_status() != LIGHT_OK) 
					break
				update_use_power(isoff()? POWER_USE_ACTIVE : POWER_USE_OFF)
				update_icon()
				update_lighting(FALSE)
				sleep(rand(5, 15))
			update_use_power( (get_status() == LIGHT_OK)? POWER_USE_ACTIVE : POWER_USE_OFF)
			update_icon()
			update_lighting(FALSE)
		flickering = FALSE

// ai attack - make lights flicker, because why not
/obj/machinery/light/attack_ai(mob/user)
	src.flicker(1)

// attack with hand - remove tube/bulb
// if hands aren't protected and the light is on, burn the player
/obj/machinery/light/attack_hand(mob/user)
	add_fingerprint(user)
	if(!lightbulb)
		to_chat(user, "There is no [get_fitting_name()] in this light.")
		return
	if(istype(user,/mob/living/carbon/human))
		var/mob/living/carbon/human/H = user
		if(H.species.can_shred(H))
			visible_message("<span class='warning'>[user.name] smashed the light!</span>", 3, "You hear a tinkle of breaking glass")
			broken()
			return
	// make it burn hands if not wearing fire-insulated gloves
	if(!isoff())
		var/prot = 0
		var/mob/living/carbon/human/H = user

		if(istype(H))
			if(H.getSpeciesOrSynthTemp(HEAT_LEVEL_1) > LIGHT_BULB_TEMPERATURE)
				prot = 1
			else if(H.gloves)
				var/obj/item/clothing/gloves/G = H.gloves
				if(G.max_heat_protection_temperature)
					if(G.max_heat_protection_temperature > LIGHT_BULB_TEMPERATURE)
						prot = 1
		else
			prot = 1

		if(prot > 0 || (COLD_RESISTANCE in user.mutations))
			to_chat(user, "You remove the [get_fitting_name()]")
		else if(TK in user.mutations)
			to_chat(user, "You telekinetically remove the [get_fitting_name()].")
		else
			to_chat(user, "You try to remove the [get_fitting_name()], but it's too hot and you don't want to burn your hand.")
			return				// if burned, don't remove the light
	else
		to_chat(user, "You remove the [get_fitting_name()].")

	// create a light tube/bulb item and put it in the user's hand
	user.put_in_active_hand(remove_bulb())	//puts it in our active hand


/obj/machinery/light/attack_tk(mob/user)
	if(!lightbulb)
		to_chat(user, "There is no [get_fitting_name()] in this light.")
		return
	to_chat(user, "You telekinetically remove the [get_fitting_name()].")
	remove_bulb()

// ghost attack - make lights flicker like an AI, but even spookier!
/obj/machinery/light/attack_ghost(mob/user)
	if(round_is_spooky())
		src.flicker(rand(2,5))
	else 
		return ..()

// break the light and make sparks if was on
/obj/machinery/light/broken(var/damtype, var/skip_sound_and_sparks = 0)
	if(!lightbulb)
		return

	if(!skip_sound_and_sparks)
		if(lightbulb && !(lightbulb.status == LIGHT_BROKEN))
			playsound(src.loc, 'sound/effects/Glasshit.ogg', 75, 1)
		if(!isoff())
			sparks.set_up(3, 1, src)
			sparks.start()
	lightbulb.status = LIGHT_BROKEN
	update_icon()
	update_lighting()

/obj/machinery/light/proc/fix()
	if(get_status() == LIGHT_OK)
		return
	lightbulb.status = LIGHT_OK
	update_use_power(POWER_USE_ACTIVE)
	update_icon()
	update_lighting()

// called when on fire
/obj/machinery/light/fire_act(datum/gas_mixture/air, exposed_temperature, exposed_volume)
	if(prob(max(0, exposed_temperature - 673)))   //0% at <400C, 100% at >500C
		broken(DAM_BURN)

//-----------------------------------------
// Readylight
//-----------------------------------------
/obj/machinery/light/small/readylight
	light_type = /obj/item/weapon/light/bulb/red/readylight
	var/state = 0

/obj/machinery/light/small/readylight/proc/set_state(var/new_state)
	state = new_state
	if(state)
		set_mode(LIGHTMODE_READY)
	else
		set_mode(null)

// the light item
// can be tube or bulb subtypes
// will fit into empty /obj/machinery/light of the corresponding type
//-----------------------------------------
// Light Bulbs
//-----------------------------------------
/obj/item/weapon/light
	icon = 'icons/obj/lighting.dmi'
	force = 2
	throwforce = 5
	w_class = ITEM_SIZE_TINY
	mass = 0.050
	damtype = DAM_BLUNT
	var/status = 0		// LIGHT_OK, LIGHT_BURNED or LIGHT_BROKEN
	var/base_state
	var/switchcount = 0	// number of times switched
	matter = list(MATERIAL_GLASS = 60)
	var/rigged = 0		// true if rigged to explode
	var/broken_chance = 2

	var/brightness_range = 2 //how much light it gives off
	var/brightness_power = 1
	var/brightness_color = "#ffffff"
	var/list/lighting_modes = list()
	var/sound_on

/obj/item/weapon/light/tube
	name = "light tube"
	desc = "A replacement light tube."
	icon_state = "ltube"
	base_state = "ltube"
	item_state = "c_tube"
	matter = list(MATERIAL_GLASS = 100)

	brightness_range = 6	// luminosity when on, also used in power calculation
	brightness_power = 3
	brightness_color = "#ffffff"
	lighting_modes = list(
		LIGHTMODE_EMERGENCY = list(l_range = 4, l_power = 1, l_color = "#da0205"),
		)
	sound_on = 'sound/machines/lightson.ogg'

/obj/item/weapon/light/tube/large
	w_class = ITEM_SIZE_SMALL
	name = "large light tube"
	brightness_range = 8
	brightness_power = 3

/obj/item/weapon/light/tube/red
	name = "red light tube"
	color = "#da0205"
	brightness_color = "#da0205"

/obj/item/weapon/light/tube/green
	name = "green light tube"
	color = "#71da02"
	brightness_color = "#71da02"

/obj/item/weapon/light/tube/blue
	name = "blue light tube"
	color = "#0271da"
	brightness_color = "#0271da"

/obj/item/weapon/light/tube/purple
	name = "purple light tube"
	color = "#6b02da"
	brightness_color = "#6b02da"

/obj/item/weapon/light/tube/pink
	name = "pink light tube"
	color = "#da0271"
	brightness_color = "#da0271"

/obj/item/weapon/light/tube/yellow
	name = "yellow light tube"
	color = "#dad702"
	brightness_color = "#dad702"

/obj/item/weapon/light/tube/orange
	name = "orange light tube"
	color = "#da6b02"
	brightness_color = "#da6b02"


/obj/item/weapon/light/bulb
	name = "light bulb"
	desc = "A replacement light bulb."
	icon_state = "lbulb"
	base_state = "lbulb"
	item_state = "contvapour"
	broken_chance = 5
	matter = list(MATERIAL_GLASS = 100)

	brightness_range = 4
	brightness_power = 2
	brightness_color = "#a0a080"
	lighting_modes = list(
		LIGHTMODE_EMERGENCY = list(l_range = 3, l_power = 1, l_color = "#da0205"),
		)

/obj/item/weapon/light/bulb/red
	name = "red light bulb"
	color = "#da0205"
	brightness_color = "#da0205"

/obj/item/weapon/light/bulb/green
	name = "green light bulb"
	color = "#71da02"
	brightness_color = "#71da02"

/obj/item/weapon/light/bulb/blue
	name = "blue light bulb"
	color = "#0271da"
	brightness_color = "#0271da"

/obj/item/weapon/light/bulb/purple
	name = "purple light bulb"
	color = "#6b02da"
	brightness_color = "#6b02da"

/obj/item/weapon/light/bulb/pink
	name = "pink light bulb"
	color = "#da0271"
	brightness_color = "#da0271"

/obj/item/weapon/light/bulb/yellow

	name = "yellow light bulb"
	color = "#dad702"
	brightness_color = "#dad702"

/obj/item/weapon/light/bulb/orange
	name = "orange light bulb"
	color = "#da6b02"
	brightness_color = "#da6b02"

/obj/item/weapon/light/bulb/red/readylight
	brightness_range = 5
	brightness_power = 1
	lighting_modes = list(
		LIGHTMODE_READY = list(l_range = 5, l_power = 1, l_color = "#00ff00"),
		)

/obj/item/weapon/light/throw_impact(atom/hit_atom)
	..()
	shatter()

/obj/item/weapon/light/bulb/fire
	name = "fire bulb"
	desc = "A replacement fire bulb."
	icon_state = "fbulb"
	base_state = "fbulb"
	item_state = "egg4"
	matter = list(MATERIAL_GLASS = 100)
	brightness_range = 4
	brightness_power = 2

// update the icon state and description of the light
/obj/item/weapon/light/update_icon()
	switch(status)
		if(LIGHT_OK)
			icon_state = base_state
			desc = "A replacement [name]."
		if(LIGHT_BURNED)
			icon_state = "[base_state]-burned"
			desc = "A burnt-out [name]."
		if(LIGHT_BROKEN)
			icon_state = "[base_state]-broken"
			desc = "A broken [name]."

/obj/item/weapon/light/New(atom/newloc, obj/machinery/light/fixture = null)
	..()
	update_icon()

// attack bulb/tube with object
// if a syringe, can inject phoron to make it explode
/obj/item/weapon/light/attackby(var/obj/item/I, var/mob/user)
	..()
	if(istype(I, /obj/item/weapon/reagent_containers/syringe))
		var/obj/item/weapon/reagent_containers/syringe/S = I

		to_chat(user, "You inject the solution into the [src].")

		if(S.reagents.has_reagent(/datum/reagent/toxin/phoron, 5))

			log_admin("LOG: [user.name] ([user.ckey]) injected a light with phoron, rigging it to explode.")
			message_admins("LOG: [user.name] ([user.ckey]) injected a light with phoron, rigging it to explode.")

			rigged = 1

		S.reagents.clear_reagents()
	else
		..()
	return

// called after an attack with a light item
// shatter light, unless it was an attempt to put it in a light socket
// now only shatter if the intent was harm

/obj/item/weapon/light/afterattack(atom/target, mob/user, proximity)
	if(!proximity) return
	if(istype(target, /obj/machinery/light))
		return
	if(user.a_intent != I_HURT)
		return

	shatter()

/obj/item/weapon/light/proc/shatter()
	if(status == LIGHT_OK || status == LIGHT_BURNED)
		src.visible_message("<span class='warning'>[name] shatters.</span>","<span class='warning'>You hear a small glass object shatter.</span>")
		status = LIGHT_BROKEN
		force = 5
		sharpness = 1
		damtype = DAM_CUT
		playsound(src.loc, 'sound/effects/Glasshit.ogg', 75, 1)
		update_icon()

/obj/item/weapon/light/proc/switch_on()
	switchcount++
	if(rigged)
		log_admin("LOG: Rigged light explosion, last touched by [fingerprintslast]")
		message_admins("LOG: Rigged light explosion, last touched by [fingerprintslast]")
		var/turf/T = get_turf(src.loc)
		spawn(0)
			sleep(2)
			explosion(T, 0, 0, 3, 5)
			sleep(1)
			qdel(src)
		status = LIGHT_BROKEN
	else if(prob(min(60, switchcount*switchcount*0.01)))
		status = LIGHT_BURNED
	else if(sound_on)
		playsound(get_turf(src),sound_on, 40)
	return status