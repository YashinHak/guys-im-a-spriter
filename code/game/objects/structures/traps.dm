/obj/structure/trap
	name = "IT'S A TRAP"
	desc = "Stepping on me is a guaranteed bad day."
	icon = 'icons/obj/hand_of_god_structures.dmi'
	icon_state = "trap"
	density = FALSE
	anchored = TRUE
	alpha = 30 //initially quite hidden when not "recharging"
	var/last_trigger = 0
	var/time_between_triggers = 1 MINUTES //takes a minute to recharge
	var/charges = INFINITY
	var/antimagic_flags = MAGIC_RESISTANCE

	var/list/static/ignore_typecache
	var/list/mob/immune_minds = list()

	var/datum/effect_system/spark_spread/spark_system

/obj/structure/trap/Initialize(mapload)
	. = ..()
	spark_system = new
	spark_system.set_up(4,1,src)
	spark_system.attach(src)

	if(!ignore_typecache)
		ignore_typecache = typecacheof(list(
			/obj/effect,
			/mob/dead))

	var/static/list/loc_connections = list(
		COMSIG_ATOM_ENTERED = PROC_REF(on_entered),
		COMSIG_ATOM_ENTERED = PROC_REF(on_trap_entered)
	)
	AddElement(/datum/element/connect_loc, loc_connections)

/obj/structure/trap/Destroy()
	qdel(spark_system)
	spark_system = null
	. = ..()

/obj/structure/trap/examine(mob/user)
	. = ..()
	if(!isliving(user))
		return
	if(user.mind && (user.mind in immune_minds))
		return
	if(get_dist(user, src) <= 1)
		. += span_notice("You reveal [src]!")
		flare()

/obj/structure/trap/proc/flare()
	// Makes the trap visible, and starts the cooldown until it's
	// able to be triggered again.
	visible_message(span_warning("[src] flares brightly!"))
	spark_system.start()
	alpha = 200
	last_trigger = world.time
	charges--
	if(charges <= 0)
		animate(src, alpha = 0, time = 1 SECONDS)
		QDEL_IN(src, 1 SECONDS)
	else
		animate(src, alpha = initial(alpha), time = time_between_triggers)

/obj/structure/trap/proc/on_trap_entered(datum/source, atom/movable/AM, ...)
	if(last_trigger + time_between_triggers > world.time)
		return
	// Don't want the traps triggered by sparks, ghosts or projectiles.
	if(is_type_in_typecache(AM, ignore_typecache))
		return
	if(ismob(AM))
		var/mob/M = AM
		if(M.mind in immune_minds)
			return
		if(M.can_block_magic())
			flare()
			return
	if(charges <= 0)
		return
	flare()
	if(isliving(AM))
		trap_effect(AM)

/obj/structure/trap/proc/trap_effect(mob/living/L)
	return

/obj/structure/trap/stun
	name = "shock trap"
	desc = "A trap that will shock and render you immobile. You'd better avoid it."
	icon_state = "trap-shock"

/obj/structure/trap/stun/trap_effect(mob/living/L)
	L.electrocute_act(30, src, zone=null, override=TRUE) // electrocute act does a message.
	L.Paralyze(100)

/obj/structure/trap/fire
	name = "flame trap"
	desc = "A trap that will set you ablaze. You'd better avoid it."
	icon_state = "trap-fire"

/obj/structure/trap/fire/trap_effect(mob/living/L)
	to_chat(L, span_danger("<B>Spontaneous combustion!</B>"))
	L.Paralyze(20)

/obj/structure/trap/fire/flare()
	..()
	new /obj/effect/hotspot(get_turf(src))


/obj/structure/trap/chill
	name = "frost trap"
	desc = "A trap that will chill you to the bone. You'd better avoid it."
	icon_state = "trap-frost"

/obj/structure/trap/chill/trap_effect(mob/living/L)
	to_chat(L, span_danger("<B>You're frozen solid!</B>"))
	L.Paralyze(20)
	L.adjust_bodytemperature(-300)
	L.apply_status_effect(/datum/status_effect/freon)


/obj/structure/trap/damage
	name = "earth trap"
	desc = "A trap that will summon a small earthquake, just for you. You'd better avoid it."
	icon_state = "trap-earth"


/obj/structure/trap/damage/trap_effect(mob/living/L)
	to_chat(L, span_danger("<B>The ground quakes beneath your feet!</B>"))
	L.Paralyze(100)
	L.adjustBruteLoss(35)

/obj/structure/trap/damage/flare()
	..()
	var/obj/structure/flora/rock/giant_rock = new(get_turf(src))
	QDEL_IN(giant_rock, 200)


/obj/structure/trap/ward
	name = "divine ward"
	desc = "A divine barrier, It looks like you could destroy it with enough effort, or wait for it to dissipate..."
	icon_state = "ward"
	density = TRUE
	time_between_triggers = 2 MINUTES //Exists for 2 minutes

/obj/structure/trap/ward/Initialize(mapload)
	. = ..()
	QDEL_IN(src, time_between_triggers)

/obj/structure/trap/proc/on_entered(datum/source, atom/movable/victim)
	SIGNAL_HANDLER
	if(last_trigger + time_between_triggers > world.time)
		return
	// Don't want the traps triggered by sparks, ghosts or projectiles.
	if(is_type_in_typecache(victim, ignore_typecache))
		return
	if(ismob(victim))
		var/mob/mob_victim = victim
		if(mob_victim.mind in immune_minds)
			return
		if(mob_victim.can_block_magic(antimagic_flags))
			flare()
			return
	if(charges <= 0)
		return
	flare()
	if(isliving(victim))
		trap_effect(victim)
