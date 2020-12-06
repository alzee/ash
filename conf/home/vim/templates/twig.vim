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
	<script src=""></script>
	<noscript></noscript>
</body>
</html>

<!--
	vim:ft=html
-->
