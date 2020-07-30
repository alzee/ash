<?php
/**
 * vim:ft=php et ts=4 sts=4
 * @author z14 <z@arcz.ee>
 * @version
 * @todo
 */

require_once 'autoload.php';


$loader = new \Twig\Loader\FilesystemLoader('./templates');
$twig = new \Twig\Environment($loader, [
    'cache' => 'cache',
    'debug' => true,
]);


if (isset($_SERVER['PATH_INFO'])) {
    $path = explode("/", trim($_SERVER['PATH_INFO'], '/'));
    switch ($path[0]) {
        case 'node':
            $template = $twig->load('node.html.twig');
            break;
        case 'list':
            $template = $twig->load('list.html.twig');
            break;
        default:
            $template = $twig->load('index.html.twig');
            break;

    }
}

echo $template->render();
