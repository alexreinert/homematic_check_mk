checkgroups = []
subgroup_os = _("Temperature, Humidity, Electrical Parameters, etc.")

register_check_parameters(
    subgroup_os,
    "homematic_humidity",
    _("Homematic Humidity"),
    Dictionary(
        title = _("Parameters for the Homematic Humidity check"),
        help = _(""),
        elements = [
            ( "warning",
                Tuple(
                title = _("Warning level of humidity"),
                elements = [
                    Integer(title = _("Lower than"), default_value = 40),
                    Integer(title = _("Higher than"), default_value = 60),
                ],
                ),
            ),
            ( "critical",
                Tuple(
                title = _("Critical level of humidity"),
                elements = [
                    Integer(title = _("Lower than"), default_value = 30),
                    Integer(title = _("Higher than"), default_value = 70),
                ],
                ),
            ),
        ],
    ),
    TextAscii(
        title = _("Name of the device"),
        ),
    match_type = "dict",
)

register_check_parameters(
    subgroup_os,
    "homematic_dutycycle",
    _("Homematic Duty cycle"),
    Dictionary(
        title = _("Parameters for the Homematic Duty cycle check"),
        help = _(""),
        elements = [
            ( "warning",
                Integer(title = _("Warning level of duty cycle"), default_value = 50)
            ),
            ( "critical",
                Integer(title = _("Critical level of duty cycle"), default_value = 70)
            ),
        ],
    ),
    TextAscii(
        title = _("Name of the device"),
        ),
    match_type = "dict",
)

