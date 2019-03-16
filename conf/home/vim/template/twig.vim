<!DOCTYPE html>
<html lang="">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1, maximum-scale=1">
<meta http-equiv="X-UA-Compatible" content="IE=edge">
<meta name="description" content="">
<meta name="author" content="">
<meta name="keyword" content="">
<title>{% block title %}Welcome!{% endblock %}</title>
<!-- Bootstrap core CSS -->
<link rel="stylesheet" type="text/css" media="" href="">
<!--external css-->
<link rel="stylesheet" type="text/css" media="" href="">
<!-- Custom styles for this template -->
<link rel="stylesheet" type="text/css" media="" href="">
        {% block stylesheets %}{% endblock %}
</head>
<body>
	{% block body %}{% endblock %}
	<header>
	</header>

	<nav>
	</nav>

	<aside>
	</aside>

	<section>
	</section>

	<footer>
	</footer>

	{% block javascripts %}{% endblock %}
    <!-- js placed at the end of the document so the pages load faster -->
	<script src=""></script>

    <!--common script for all pages-->
	<script src=""></script>

    <!--script for this page-->
	<script src=""></script>

	<noscript></noscript>
</body>
</html>

<!--
	vim:ft=html
-->
